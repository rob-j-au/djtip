# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Devise parameter sanitization
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  # OpenTelemetry enhancements
  before_action :add_user_context_to_trace
  around_action :trace_request_with_context

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
  
  private
  
  # Add user context to current trace span
  def add_user_context_to_trace
    return unless current_user
    
    span = OpenTelemetry::Trace.current_span
    return unless span.recording?
    
    # Add user attributes following OpenTelemetry semantic conventions
    span.set_attribute('enduser.id', current_user.id.to_s)
    span.set_attribute('enduser.email', current_user.email) if current_user.email
    span.set_attribute('enduser.name', current_user.name) if current_user.respond_to?(:name)
  rescue => e
    Rails.logger.warn "Failed to add user context to trace: #{e.message}"
  end
  
  # Wrap request in a custom span with enhanced context
  def trace_request_with_context
    tracer = OpenTelemetry.tracer_provider.tracer('djtip', '1.0.0')
    
    attributes = {
      'http.route' => "#{controller_name}##{action_name}",
      'http.target' => request.fullpath,
      'http.method' => request.method,
      'http.client_ip' => request.remote_ip
    }
    attributes['http.user_agent'] = request.user_agent if request.user_agent.present?
    
    tracer.in_span(
      "#{controller_name}##{action_name}",
      attributes: attributes,
      kind: :server
    ) do |span|
      begin
        result = yield
        
        # Add response context
        span.set_attribute('http.status_code', response.status)
        span.set_attribute('http.response_content_length', response.content_length) if response.content_length
        
        result
      rescue => e
        # Enhanced error tracking
        span.record_exception(e)
        span.status = OpenTelemetry::Trace::Status.error("#{e.class}: #{e.message}")
        
        # Add error context
        span.set_attribute('error.type', e.class.name)
        span.set_attribute('error.message', e.message)
        span.set_attribute('error.stack', e.backtrace&.first(5)&.join("\n")) if e.backtrace
        
        raise
      end
    end
  end
end
