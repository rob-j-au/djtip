# frozen_string_literal: true

# BusinessMetrics concern for tracking business events in OpenTelemetry and Prometheus
#
# Usage:
#   class Tip
#     include Mongoid::Document
#     include BusinessMetrics
#     
#     after_create :track_tip_created
#     
#     def track_tip_created
#       track_business_event('tip.created', {
#         'tip.amount' => amount,
#         'tip.currency' => 'USD',
#         'event.id' => event_id.to_s
#       })
#     end
#   end
#
module BusinessMetrics
  extend ActiveSupport::Concern

  # Track a business event in both OpenTelemetry (as span event) and Prometheus (as metric)
  #
  # @param event_name [String] name of the business event (e.g., 'tip.created', 'user.registered')
  # @param attributes [Hash] additional context attributes
  # @param metric_labels [Hash] optional labels for Prometheus metric (defaults to extracting from attributes)
  #
  def track_business_event(event_name, attributes = {}, metric_labels: nil)
    # Add event to current trace span
    add_span_event(event_name, attributes)
    
    # Increment Prometheus counter
    increment_business_metric(event_name, metric_labels || extract_metric_labels(attributes))
    
    # Log the event
    Rails.logger.info("Business event: #{event_name} - #{attributes.inspect}")
  end
  
  # Track a business metric value (for gauges/histograms)
  #
  # @param metric_name [String] name of the metric
  # @param value [Numeric] the value to record
  # @param attributes [Hash] additional context
  #
  def track_business_metric(metric_name, value, attributes = {})
    span = OpenTelemetry::Trace.current_span
    if span.recording?
      span.set_attribute("metric.#{metric_name}", value)
      attributes.each { |k, v| span.set_attribute(k.to_s, v) }
    end
    
    Rails.logger.info("Business metric: #{metric_name} = #{value}")
  end
  
  private
  
  def add_span_event(event_name, attributes)
    span = OpenTelemetry::Trace.current_span
    return unless span.recording?
    
    # Convert all values to OpenTelemetry-compatible types
    otel_attributes = attributes.transform_values do |value|
      case value
      when String, Integer, Float, TrueClass, FalseClass
        value
      when Array
        value.map(&:to_s)
      else
        value.to_s
      end
    end
    
    span.add_event(event_name, attributes: otel_attributes)
  rescue => e
    Rails.logger.warn("Failed to add span event: #{e.message}")
  end
  
  def increment_business_metric(event_name, labels)
    return unless defined?(CUSTOM_METRICS)
    
    # Dynamically create or get metric
    metric_key = event_name.gsub('.', '_').to_sym
    
    unless CUSTOM_METRICS.key?(metric_key)
      # Create new counter if it doesn't exist
      CUSTOM_METRICS[metric_key] = Prometheus::Client.registry.counter(
        "#{metric_key}_total".to_sym,
        docstring: "Total count of #{event_name} events",
        labels: labels.keys
      )
    end
    
    CUSTOM_METRICS[metric_key].increment(labels: labels)
  rescue => e
    Rails.logger.warn("Failed to increment business metric: #{e.message}")
  end
  
  def extract_metric_labels(attributes)
    # Extract useful labels from attributes (limit to avoid high cardinality)
    labels = {}
    
    # Common label patterns
    labels[:event_id] = attributes['event.id'] if attributes['event.id']
    labels[:user_id] = attributes['user.id'] if attributes['user.id']
    labels[:status] = attributes['status'] if attributes['status']
    labels[:type] = attributes['type'] if attributes['type']
    
    # Amount ranges (to avoid high cardinality)
    if attributes['tip.amount']
      amount = attributes['tip.amount'].to_f
      labels[:amount_range] = case amount
                              when 0..10 then 'small'
                              when 10..50 then 'medium'
                              when 50..100 then 'large'
                              else 'xlarge'
                              end
    end
    
    labels.compact
  end
end
