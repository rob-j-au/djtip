# Custom logger formatter that includes OpenTelemetry trace IDs
# This enables log-trace correlation in Grafana
#
# Note: Disabled for now due to compatibility issues with Rails TaggedLogging
# Trace IDs are still available via ApplicationController's before_action

# Rails.application.config.after_initialize do
#   Rails.logger.info "Trace ID logging available via ApplicationController"
# end
