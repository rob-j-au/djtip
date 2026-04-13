# Custom logger formatter that includes OpenTelemetry trace IDs
# This enables log-trace correlation in Grafana

class TraceIdLogFormatter < ActiveSupport::Logger::SimpleFormatter
  def call(severity, timestamp, progname, msg)
    trace_id = current_trace_id
    
    if trace_id
      "[#{trace_id}] #{super}"
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

# Apply custom formatter to Rails logger
# Note: We keep the existing tagged logging functionality
Rails.application.config.after_initialize do
  if Rails.logger.formatter
    # Wrap existing formatter to add trace IDs
    original_formatter = Rails.logger.formatter
    Rails.logger.formatter = proc do |severity, timestamp, progname, msg|
      trace_id = begin
        span_context = OpenTelemetry::Trace.current_span.context
        span_context.valid? ? span_context.hex_trace_id : nil
      rescue
        nil
      end
      
      formatted = original_formatter.call(severity, timestamp, progname, msg)
      trace_id ? "[#{trace_id}] #{formatted}" : formatted
    end
  end
  
  Rails.logger.info "Trace ID logging enabled"
end
