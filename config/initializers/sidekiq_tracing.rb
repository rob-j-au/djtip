# Enhanced Sidekiq tracing middleware
# Adds job-specific context and metrics to OpenTelemetry traces

return unless defined?(Sidekiq)

class SidekiqTracingMiddleware
  def call(worker, job, queue)
    tracer = OpenTelemetry.tracer_provider.tracer('djtip', '1.0.0')
    
    tracer.in_span(
      "#{worker.class.name}.perform",
      attributes: {
        'messaging.system' => 'sidekiq',
        'messaging.destination' => queue,
        'messaging.destination_kind' => 'queue',
        'messaging.operation' => 'process',
        'messaging.message_id' => job['jid'],
        'job.class' => worker.class.name,
        'job.queue' => queue,
        'job.retry_count' => job['retry_count'] || 0,
        'job.created_at' => job['created_at'],
        'job.enqueued_at' => job['enqueued_at']
      },
      kind: :consumer
    ) do |span|
      start_time = Time.now
      
      begin
        result = yield
        
        # Add success metrics
        duration = Time.now - start_time
        span.set_attribute('job.duration_seconds', duration)
        span.set_attribute('job.status', 'success')
        
        # Update Prometheus metrics
        if defined?(CUSTOM_METRICS)
          CUSTOM_METRICS[:sidekiq_jobs].increment(
            labels: { queue: queue, status: 'success' }
          )
          CUSTOM_METRICS[:sidekiq_job_duration].observe(
            duration,
            labels: { queue: queue, job_class: worker.class.name }
          )
        end
        
        result
      rescue => e
        # Add failure context
        duration = Time.now - start_time
        span.set_attribute('job.duration_seconds', duration)
        span.set_attribute('job.status', 'failed')
        span.set_attribute('job.error_class', e.class.name)
        span.set_attribute('job.error_message', e.message)
        
        span.record_exception(e)
        span.status = OpenTelemetry::Trace::Status.error(e.message)
        
        # Update Prometheus metrics
        if defined?(CUSTOM_METRICS)
          CUSTOM_METRICS[:sidekiq_jobs].increment(
            labels: { queue: queue, status: 'failed' }
          )
        end
        
        raise
      end
    end
  end
end

# Register middleware
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add SidekiqTracingMiddleware
  end
end

Rails.logger.info "Sidekiq tracing middleware registered"
