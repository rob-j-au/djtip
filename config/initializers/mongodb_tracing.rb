# Enhanced MongoDB tracing
# Adds query performance tracking and slow query detection

return unless defined?(Mongoid)

# Subscribe to MongoDB command events for detailed tracking
Mongo::Monitoring::Global.subscribe(Mongo::Monitoring::COMMAND, Class.new do
  def started(event)
    # Store start time for duration calculation
    Thread.current[:mongo_command_start] ||= {}
    Thread.current[:mongo_command_start][event.request_id] = Time.now
  end
  
  def succeeded(event)
    start_time = Thread.current[:mongo_command_start]&.delete(event.request_id)
    return unless start_time
    
    duration = Time.now - start_time
    
    # Log slow queries (>100ms)
    if duration > 0.1
      Rails.logger.warn(
        "Slow MongoDB query detected: #{event.command_name} " \
        "on #{event.database_name}.#{collection_name(event)} " \
        "took #{(duration * 1000).round(2)}ms"
      )
      
      # Add to current span if available
      span = OpenTelemetry::Trace.current_span
      if span.recording?
        span.add_event('slow_query', attributes: {
          'db.operation' => event.command_name,
          'db.mongodb.collection' => collection_name(event),
          'db.duration_ms' => (duration * 1000).round(2)
        })
      end
    end
    
    # Update Prometheus metrics
    if defined?(CUSTOM_METRICS)
      CUSTOM_METRICS[:db_query_duration].observe(
        duration,
        labels: { operation: event.command_name }
      )
    end
  end
  
  def failed(event)
    Thread.current[:mongo_command_start]&.delete(event.request_id)
    
    Rails.logger.error(
      "MongoDB query failed: #{event.command_name} " \
      "on #{event.database_name} - #{event.failure}"
    )
  end
  
  private
  
  def collection_name(event)
    event.command[event.command_name.to_s] || 'unknown'
  rescue
    'unknown'
  end
end.new)

Rails.logger.info "MongoDB enhanced tracing enabled"
