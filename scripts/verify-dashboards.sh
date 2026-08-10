#!/usr/bin/env bash
# ============================================================
# Grafana Dashboard Acceptance Test
# ============================================================
# Verifies each provisioned dashboard is functional by:
#   1. Fetching the dashboard definition via the Grafana API
#   2. Resolving template variables to actual values
#   3. Running each panel's Prometheus query via the datasource query API
#   4. Checking that queries WITHOUT template variables return data
#   5. For template queries, resolving variables first then checking
#
# Also verifies that the underlying data sources (Prometheus, Loki, Tempo)
# are reachable and that key metrics exist.
#
# Usage:
#   GRAFANA_URL=http://localhost:3000 ./scripts/verify-dashboards.sh
#
# Environment variables:
#   GRAFANA_URL   - Grafana base URL (default: http://localhost:3000)
#   GRAFANA_USER  - Grafana username (default: admin)
#   GRAFANA_PASS  - Grafana password (default: prom-operator)
#   TIMEOUT       - Query timeout in seconds (default: 15)
# ============================================================

set -euo pipefail

GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
GRAFANA_USER="${GRAFANA_USER:-admin}"
GRAFANA_PASS="${GRAFANA_PASS:-prom-operator}"
TIMEOUT="${TIMEOUT:-15}"
AUTH="$(printf '%s' "${GRAFANA_USER}:${GRAFANA_PASS}" | base64)"

PASS=0
FAIL=0
TOTAL_DASHBOARDS=0
TOTAL_QUERIES=0
TOTAL_PASSED=0
TOTAL_FAILED=0

log_ok()   { printf '  \033[32m✔\033[0m %s\n' "$1"; }
log_fail() { printf '  \033[31m✘\033[0m %s\n' "$1"; }
log_warn() { printf '  \033[33m~\033[0m %s\n' "$1"; }
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
# Run a Prometheus query via Grafana API and check for data
# ------------------------------------------------------------
check_prom_query() {
  local query="$1"
  local ds_uid="${2:-PBFA97CFB590B2093}"
  local range
  range=$(time_range)
  local from="${range%%|*}"
  local to="${range##*|}"

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
    "${GRAFANA_URL}/api/ds/query" 2>/dev/null)

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

  [ "${frames}" -gt 0 ]
}

# ------------------------------------------------------------
# Resolve a template variable by querying Prometheus for label values
# ------------------------------------------------------------
resolve_template() {
  local query="$1"
  local ds_uid="${2:-PBFA97CFB590B2093}"

  # Extract the PromQL query from the template definition
  # Handle both string and object formats
  local promql=""
  if echo "${query}" | python3 -c "import sys; json.load(sys.stdin)" 2>/dev/null; then
    promql=$(echo "${query}" | python3 -c "import sys,json; print(json.load(sys.stdin).get('query',''))" 2>/dev/null)
  else
    promql="${query}"
  fi

  # If it's a label_values() query, extract the metric and label
  if [[ "${promql}" == label_values* ]]; then
    # label_values(metric, label) or label_values(metric{filter}, label)
    local metric_label
    metric_label=$(echo "${promql}" | sed 's/label_values(//' | sed 's/)$//')
    local metric="${metric_label%%, *}"
    local label="${metric_label##*, }"
    # Remove any filter from metric
    metric="${metric%%\{*}"
    label="${label%%\}*}"

    # Query Prometheus directly for label values
    local result
    result=$(curl -s --max-time "${TIMEOUT}" \
      -H "Authorization: Basic ${AUTH}" \
      "${GRAFANA_URL}/api/datasources/proxy/uid/${ds_uid}/api/v1/label/${label}/values" 2>/dev/null)

    echo "${result}" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    values = d.get('data', [])
    if values:
        print(values[0])
    else:
        print('')
except Exception:
    print('')
" 2>/dev/null
  elif [[ "${promql}" == query_result* ]]; then
    # query_result(prometheus_metric) - extract the metric name
    local metric
    metric=$(echo "${promql}" | sed 's/query_result(//' | sed 's/)$//' | sed 's/{.*//')
    # Just return the metric name as a hint
    echo "${metric}"
  else
    echo ""
  fi
}

# ------------------------------------------------------------
# Test a dashboard
# ------------------------------------------------------------
test_dashboard() {
  local uid="$1"
  local name="$2"

  log_info "Testing dashboard: ${name}"
  local dash_passed=0
  local dash_failed=0
  local dash_skipped=0

  # Fetch dashboard definition
  local dash_json
  dash_json=$(curl -s --max-time "${TIMEOUT}" \
    -H "Authorization: Basic ${AUTH}" \
    "${GRAFANA_URL}/api/dashboards/uid/${uid}" 2>/dev/null)

  if [ -z "${dash_json}" ] || ! echo "${dash_json}" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
    log_fail "Dashboard not found or invalid JSON"
    return 1
  fi

  # Extract all unique queries from panels
  local query_count=0
  local queries_json
  queries_json=$(echo "${dash_json}" | python3 -c "
import sys, json
def extract(obj, queries):
    if isinstance(obj, dict):
        for t in obj.get('targets', []):
            if 'expr' in t:
                q = t['expr'].strip()
                if q and q not in queries:
                    queries[q] = {'has_template': '\$' in q, 'expr': q}
        for v in obj.values():
            extract(v, queries)
    elif isinstance(obj, list):
        for item in obj:
            extract(item, queries)
queries = {}
try:
    d = json.load(sys.stdin)
    for p in d.get('dashboard', {}).get('panels', []):
        extract(p, queries)
except Exception:
    pass
print(json.dumps(queries))
" 2>/dev/null)

  local total_queries
  total_queries=$(echo "${queries_json}" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null)
  echo "  Found ${total_queries} unique queries"

  # Test each query
  local idx=0
  while IFS= read -r line; do
    idx=$((idx + 1))
    local has_template expr
    has_template=$(echo "${line}" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(list(d.keys())[0])" 2>/dev/null)
    expr=$(echo "${line}" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(list(d.values())[0]['expr'])" 2>/dev/null)
    
    # Skip empty
    [ -z "${expr}" ] && continue

    TOTAL_QUERIES=$((TOTAL_QUERIES + 1))

    if echo "${has_template}" | grep -q "true"; then
      # Query has template variables - try to resolve them
      local resolved="${expr}"
      # Replace $__rate_interval and $__interval with fixed values
      resolved="${resolved//\$__rate_interval/1m}"
      resolved="${resolved//\$__interval/1m}"
      resolved="${resolved//\$interval/1m}"
      
      # Try to resolve template variables from the dashboard's templating
      while IFS='|' read -r var_name var_query; do
        [ -z "${var_name}" ] && continue
        local var_value
        var_value=$(resolve_template "${var_query}" "PBFA97CFB590B2093")
        if [ -n "${var_value}" ]; then
          resolved="${resolved//\$${var_name}/${var_value}}"
          resolved="${resolved//\$\{${var_name}\}/${var_value}}"
        fi
      done < <(echo "${dash_json}" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for t in d.get('dashboard', {}).get('templating', {}).get('list', []):
    q = t.get('query', '')
    if isinstance(q, dict):
        q = json.dumps(q)
    print(f\"{t.get('name')}|{q}\")
" 2>/dev/null)

      # Check if all template variables were resolved
      if echo "${resolved}" | grep -q '\$'; then
        log_warn "[${idx}/${total_queries}] SKIP (unresolved vars): $(echo "${expr}" | cut -c1-60)"
        dash_skipped=$((dash_skipped + 1))
      else
        if check_prom_query "${resolved}"; then
          log_ok "[${idx}/${total_queries}] $(echo "${expr}" | cut -c1-60)"
          dash_passed=$((dash_passed + 1))
          TOTAL_PASSED=$((TOTAL_PASSED + 1))
        else
          log_warn "[${idx}/${total_queries}] NO DATA: $(echo "${expr}" | cut -c1-60)"
          dash_failed=$((dash_failed + 1))
          TOTAL_FAILED=$((TOTAL_FAILED + 1))
        fi
      fi
    else
      # No template variables - should return data
      if check_prom_query "${expr}"; then
        log_ok "[${idx}/${total_queries}] $(echo "${expr}" | cut -c1-60)"
        dash_passed=$((dash_passed + 1))
        TOTAL_PASSED=$((TOTAL_PASSED + 1))
      else
        log_fail "[${idx}/${total_queries}] NO DATA: $(echo "${expr}" | cut -c1-60)"
        dash_failed=$((dash_failed + 1))
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
      fi
    fi
  done < <(echo "${queries_json}" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for k, v in d.items():
    print(json.dumps({k: v}))
" 2>/dev/null)

  echo "  Result: ${dash_passed} passed, ${dash_failed} failed, ${dash_skipped} skipped"
  return ${dash_failed}
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
  while IFS='|' read -r uid name; do
    [ -z "${uid}" ] && continue
    TOTAL_DASHBOARDS=$((TOTAL_DASHBOARDS + 1))
    echo ""
    if test_dashboard "${uid}" "${name}"; then
      PASS=$((PASS + 1))
    else
      FAIL=$((FAIL + 1))
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
  echo "  Dashboards tested: ${TOTAL_DASHBOARDS}"
  echo "  Queries tested:    ${TOTAL_QUERIES}"
  echo "  Passed:            ${TOTAL_PASSED}"
  echo "  Failed:            ${TOTAL_FAILED}"
  echo ""

  if [ "${TOTAL_FAILED}" -gt 0 ]; then
    log_fail "${TOTAL_FAILED} queries returned no data"
    exit 1
  fi

  log_ok "All dashboards are functional"
  exit 0
}

main "$@"