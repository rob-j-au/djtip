class ImageUploader < Shrine
  # Plugins for image processing and validation
  plugin :derivatives
  plugin :validation_helpers
  plugin :store_dimensions

  # File validation
  Attacher.validate do
    validate_max_size 5 * 1024 * 1024, message: 'is too large (max is 5MB)'
    validate_mime_type_inclusion ['image/jpeg', 'image/png', 'image/gif']
  end

  # Define derivatives for different image sizes
  Attacher.derivatives do |original|
    derivatives = {}
    
    # Always create derivatives for image files (validation handles MIME type checking)
    begin
      # Create thumbnail version (150x150)
      derivatives[:thumb] = process_upload(original, 150, 150)
      
      # Create medium version (300x300)
      derivatives[:medium] = process_upload(original, 300, 300)
    rescue => e
      # Skip derivative creation if image processing fails
      Rails.logger.warn "Failed to create image derivatives: #{e.message}"
    end
    
    derivatives
  end

  # Helper method to check if file is an image
  def image?(io)
    %w[image/jpeg image/png image/gif].include?(io.mime_type)
  end

  private

  # Helper method to process image uploads with specified dimensions
  def process_upload(io, width, height)
    # Handle both UploadedFile and Tempfile objects
    source_file = io.respond_to?(:download) ? io.download : io
    pipeline = ImageProcessing::Vips.source(source_file)
    
    # Resize and convert to JPG
    pipeline = pipeline
      .resize_to_limit!(width, height)
      .convert('jpg')
      .saver(quality: 85)
      .call
    
    # Return a File object with the correct extension
    File.open(pipeline.path, 'rb')
  end
end
