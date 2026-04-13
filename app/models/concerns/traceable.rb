# frozen_string_literal: true

# Traceable concern for adding OpenTelemetry tracing to models
# 
# Usage:
#   class Event
#     include Mongoid::Document
#     include Traceable
#     
#     trace_method :calculate_tips_total
#     trace_method :send_notifications, span_name: 'event.notify_attendees'
#   end
#
module Traceable
  extend ActiveSupport::Concern

  class_methods do
    # Automatically trace a method with OpenTelemetry
    # 
    # @param method_name [Symbol] the method to trace
    # @param span_name [String] optional custom span name (defaults to "ClassName.method_name")
    # @param attributes [Hash] optional static attributes to add to the span
    #
    # Example:
    #   trace_method :process_payment, 
    #                span_name: 'payment.process',
    #                attributes: { 'payment.provider' => 'stripe' }
    #
    def trace_method(method_name, span_name: nil, attributes: {})
      span_name ||= "#{name}.#{method_name}"
      
      # Store original method
      original_method = instance_method(method_name)
      
      # Redefine method with tracing
      define_method(method_name) do |*args, **kwargs, &block|
        tracer = OpenTelemetry.tracer_provider.tracer('djtip', '1.0.0')
        
        tracer.in_span(span_name, attributes: attributes) do |span|
          begin
            # Add model context
            span.set_attribute('db.model', self.class.name)
            span.set_attribute('db.record_id', id.to_s) if respond_to?(:id) && id
            
            # Call original method
            if kwargs.empty?
              original_method.bind(self).call(*args, &block)
            else
              original_method.bind(self).call(*args, **kwargs, &block)
            end
          rescue => e
            span.record_exception(e)
            span.status = OpenTelemetry::Trace::Status.error(e.message)
            raise
          end
        end
      end
    end
  end

  # Instance method to create a traced block
  # 
  # Usage:
  #   def complex_operation
  #     trace_span('event.complex_operation') do
  #       # ... complex code
  #     end
  #   end
  #
  def trace_span(name, attributes = {})
    tracer = OpenTelemetry.tracer_provider.tracer('djtip', '1.0.0')
    
    tracer.in_span(name, attributes: attributes) do |span|
      # Add model context
      span.set_attribute('db.model', self.class.name)
      span.set_attribute('db.record_id', id.to_s) if respond_to?(:id) && id
      
      begin
        yield(span)
      rescue => e
        span.record_exception(e)
        span.status = OpenTelemetry::Trace::Status.error(e.message)
        raise
      end
    end
  end
  
  # Add attributes to the current span
  def add_trace_attributes(attributes)
    span = OpenTelemetry::Trace.current_span
    return unless span.recording?
    
    attributes.each do |key, value|
      span.set_attribute(key.to_s, value)
    end
  end
end
