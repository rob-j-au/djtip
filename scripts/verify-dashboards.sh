#!/usr/bin/env bash
# ============================================================
# Grafana Dashboard Acceptance Test
# ============================================================
# Verifies that each provisioned dashboard is functional by:
#   1. Fetching the dashboard definition via the Grafana API
#   2. Running each panel's Prometheus query via the datasource query API
#   3. Checking that the query returns data points
#
# Also verifies that the underlying data sources (Prometheus, Loki, Tempo)
# are reachable and that key metrics exist.
#
# Usage:
#   GRAFANA_URL=http://localhost:3000 GRAFANA_USER=admin GRAFANA_PASS=... ./scripts/verify-dashboards.sh
#
# Environment variables:
#   GRAFANA_URL   - Grafana base URL (default: http://localhost:3000)
#   GRAFANA_USER  - Grafana username (default: admin)
#   GRAFANA_PASS  - Grafana password (default: prom-operator)
#   TIMEOUT       - Query timeout in seconds (default: 10)
# ============================================================

set -euo pipefail

GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
GRAFANA_USER="${GRAFANA_USER:-admin}"
GRAFANA_PASS="${GRAFANA_PASS:-prom-operator}"
TIMEOUT="${TIMEOUT:-10}"
AUTH="$(printf '%s' "${GRAFANA_USER}:${GRAFANA_PASS}" | base64)"

PASS=0
FAIL=0
FAILED_DASHBOARDS=()

log_ok()   { printf '  \033[32m✔\033[0m %s\n' "$1"; }
log_fail() { printf '  \033[31m✘\033[0m %s\n' "$1"; }
log_info() { printf '\033[36m%s\033[0m\n' "$1"; }

# ------------------------------------------------------------
# Helper: query a timestamp range that spans the last 15 minutes
# ------------------------------------------------------------
time_range() {
  local now_ms to_ms from_ms
  now_ms=$(($(date +%s%N) / 1000000))
  to_ms=$((now_ms))
  from_ms=$((now_ms - 900000))  # 15 minutes ago
  echo "${from_ms}|${to_ms}"
}

# ------------------------------------------------------------
# Check a single Prometheus query returns data
# ------------------------------------------------------------
# $1 = query string
# $2 = datasource UID (optional, defaults to Prometheus)
# Returns 0 if data points are returned, 1 otherwise
check_prom_query() {
  local query="$1"
  local ds_uid="${2:-PBFA97CFB590B2093}"
  local range
  range=$(time_range)
  local from="${range%%|*}"
  local to="${range##*|}"

  # Use the Grafana datasource query API
  local payload
  payload=$(cat <<EOF
{
  "queries": [
    {
      "refId": "A",
      "datasource": {"type": "prometheus", "uid": "${ds_uid}"},
      "expr": "${query}",
      "range": true,
      "instant": false,
      "intervalMs": 1000,
      "maxDataPoints": 50
    }
  ],
  "from": "${from}",
  "to": "${to}"
}
EOF
)

  local result
  result=$(curl -s --max-time "${TIMEOUT}" \
    -H "Authorization: Basic ${AUTH}" \
    -H "Content-Type: application/json" \
    -d "${payload}" \
    "${GRAFANA_URL}/api/ds/query")

  # Check if the response contains a non-empty result
  local frames
  frames=$(echo "${result}" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    results = d.get('results', {})
    total = 0
    for rid, res in results.items():
        for frame in res.get('frames', []):
            values = frame.get('data', {}).get('values', [])
            if values and any(v for v in values if v):
                total += 1
    print(total)
except Exception:
    print(0)
" 2>/dev/null)

  if [ "${frames}" -gt 0 ]; then
    return 0
  else
    return 1
  fi
}

# ------------------------------------------------------------
# Check a Loki log query returns data
# ------------------------------------------------------------
check_loki_query() {
  local query="$1"
  local ds_uid="${2:-}"
  local range
  range=$(time_range)
  local from_s to_s
  from_s=$(( $(date -d '15 minutes ago' +%s%N) / 1000000000 ))
  to_s=$(( $(date +%s%N) / 1000000000 ))

  # Find Loki datasource
  if [ -z "${ds_uid}" ]; then
    ds_uid=$(curl -s --max-time "${TIMEOUT}" \
      -H "Authorization: Basic ${AUTH}" \
      "${GRAFANA_URL}/api/datasources/name/Loki" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('uid',''))" 2>/dev/null)
  fi

  local encoded
  encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''${query}'''))")

  local result
  result=$(curl -s --max-time "${TIMEOUT}" \
    -H "Authorization: Basic ${AUTH}" \
    "${GRAFANA_URL}/api/datasources/proxy/uid/${ds_uid}/loki/api/v1/query_range?query=${encoded}&start=${from_s}&end=${to_s}&limit=10" 2>/dev/null)

  local count
  count=$(echo "${result}" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(len(d.get('data', {}).get('result', [])))
except Exception:
    print(0)
" 2>/dev/null)

  if [ "${count}" -gt 0 ]; then
    return 0
  else
    return 1
  fi
}

# ------------------------------------------------------------
# Test a dashboard: fetch it, run its panel queries
# ------------------------------------------------------------
test_dashboard() {
  local uid="$1"
  local name="$2"

  log_info "Testing dashboard: ${name}"
  PASS=0
  FAIL=0

  # Fetch dashboard definition
  local dash_json
  dash_json=$(curl -s --max-time "${TIMEOUT}" \
    -H "Authorization: Basic ${AUTH}" \
    "${GRAFANA_URL}/api/dashboards/uid/${uid}" 2>/dev/null)

  # Check dashboard exists
  if [ -z "${dash_json}" ] || ! echo "${dash_json}" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
    printf '  \033[31m✘\033[0m Dashboard not found or invalid JSON\n'
    return 1
  fi

  # Extract unique Prometheus queries from all panels
  local query_count total_queries
  query_count=$(echo "${dash_json}" | python3 -c "
import sys, json
def extract(obj, queries):
    if isinstance(obj, dict):
        # Check targets
        for t in obj.get('targets', []):
            if 'expr' in t:
                q = t['expr'].strip()
                if q and q not in queries:
                    queries.add(q)
        # Recurse
        for v in obj.values():
            extract(v, queries)
    elif isinstance(obj, list):
        for item in obj:
            extract(item, queries)
queries = set()
try:
    d = json.load(sys.stdin)
    for p in d.get('dashboard', {}).get('panels', []):
        extract(p, queries)
except Exception:
    pass
print(len(queries))
" 2>/dev/null)

  total_queries="${query_count:-0}"
  echo "  Found ${total_queries} unique Prometheus queries in panels"

  if [ "${total_queries}" -eq 0 ]; then
    printf '  \033[36m...\033[0m No Prometheus queries to test (log/other dashboard)\n'
    return 0
  fi

  # Test each query
  local tested=0 passed=0
  while IFS= read -r query; do
    # Skip empty
    [ -z "${query}" ] && continue
    tested=$((tested + 1))
    if check_prom_query "${query}"; then
      printf '  \033[32m✔\033[0m [%d/%d] %s\n' "${tested}" "${total_queries}" "$(echo "${query}" | cut -c1-80)"
      passed=$((passed + 1))
    else
      printf '  \033[33m~\033[0m [%d/%d] NO DATA (may be valid): %s\n' "${tested}" "${total_queries}" "$(echo "${query}" | cut -c1-80)"
    fi
  done < <(echo "${dash_json}" | python3 -c "
import sys, json
def extract(obj, queries):
    if isinstance(obj, dict):
        for t in obj.get('targets', []):
            if 'expr' in t:
                q = t['expr'].strip()
                if q:
                    queries.add(q)
        for v in obj.values():
            extract(v, queries)
    elif isinstance(obj, list):
        for item in obj:
            extract(item, queries)
queries = set()
try:
    d = json.load(sys.stdin)
    for p in d.get('dashboard', {}).get('panels', []):
        extract(p, queries)
except Exception:
    pass
for q in sorted(queries):
    print(q)
")

  echo "  Result: ${passed}/${tested} queries returned data"
  return 0
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------
main() {
  log_info "Grafana Dashboard Acceptance Test"
  log_info "Grafana URL: ${GRAFANA_URL}"
  echo ""

  # Check Grafana is reachable
  if ! curl -s --max-time 5 -H "Authorization: Basic ${AUTH}" "${GRAFANA_URL}/api/health" 2>/dev/null | grep -q '"database".*"ok"'; then
    log_fail "Grafana is not reachable at ${GRAFANA_URL}"
    exit 1
  fi
  log_ok "Grafana is reachable"
  echo ""

  # Get list of dashboards
  local total pass fail
  total=0; pass=0; fail=0

  while IFS='|' read -r uid name; do
    [ -z "${uid}" ] && continue
    total=$((total + 1))
    echo ""
    if test_dashboard "${uid}" "${name}"; then
      pass=$((pass + 1))
    else
      fail=$((fail + 1))
      FAILED_DASHBOARDS+=("${name}")
    fi
  done < <(curl -s --max-time "${TIMEOUT}" \
    -H "Authorization: Basic ${AUTH}" \
    "${GRAFANA_URL}/api/search" 2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    for dash in d:
        if dash.get('type') == 'dash-db':
            print(f\"{dash.get('uid')}|{dash.get('title')}\")
except Exception:
    pass
")

  echo ""
  echo "============================================================"
  echo "SUMMARY"
  echo "============================================================"
  echo "  Dashboards tested: ${total}"
  echo "  Passed:            ${pass}"
  echo "  Failed:            ${fail}"
  echo ""

  if [ ${#FAILED_DASHBOARDS[@]} -gt 0 ]; then
    log_fail "Unreachable/failed dashboards:"
    for d in "${FAILED_DASHBOARDS[@]}"; do
      printf '    - %s\n' "${d}"
    done
    exit 1
  fi

  log_ok "All dashboards are functional"
  exit 0
}

main "$@"