# Custom logger formatter that includes OpenTelemetry trace IDs
# This enables log-trace correlation in Grafana

class TraceIdLogFormatter < ActiveSupport::TaggedLogging::Formatter
  def call(severity, timestamp, progname, msg)
    trace_id = current_trace_id
    
    if trace_id
      # Add trace ID as a tag
      tags_text = tags.any? ? "#{tags_text} " : ""
      "[#{trace_id}] #{tags_text}#{msg}\n"
    else
      super
    end
  end
  
  private
  
  def current_trace_id
    # Try to get from thread-local first (set in ApplicationController)
    trace_id = Thread.current[:trace_id]
    return trace_id if trace_id
    
    # Otherwise get from current span
    span_context = OpenTelemetry::Trace.current_span.context
    return nil unless span_context.valid?
    
    span_context.hex_trace_id
  rescue
    nil
  end
end

# Apply custom formatter to Rails logger with tagged logging support
Rails.application.config.after_initialize do
  # Use TaggedLogging wrapper with our custom formatter
  logger = ActiveSupport::Logger.new($stdout)
  logger.formatter = TraceIdLogFormatter.new
  Rails.logger = ActiveSupport::TaggedLogging.new(logger)
  Rails.logger.info "Trace ID logging enabled"
end
