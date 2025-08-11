class Api::V1::BaseController < ApplicationController
  # Skip CSRF protection for API requests
  skip_before_action :verify_authenticity_token
  
  # Handle common API errors
  rescue_from Mongoid::Errors::DocumentNotFound, with: :not_found
  rescue_from Mongoid::Errors::Validations, with: :validation_errors
  
  private
  
  def not_found
    render json: { error: 'Resource not found' }, status: :not_found
  end
  
  def validation_errors(exception)
    render json: { 
      error: 'Validation failed', 
      details: exception.document.errors.full_messages 
    }, status: :unprocessable_content
  end
end
