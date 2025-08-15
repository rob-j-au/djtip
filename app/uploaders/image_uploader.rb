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
    magick = ImageProcessing::MiniMagick.source(original)
    
    {
      thumb: magick.resize_to_limit(150, 150).convert("jpg").call,
      medium: magick.resize_to_limit(300, 300).convert("jpg").call
    }
  end

  # Helper method to check if file is an image
  def image?(io)
    %w[image/jpeg image/png image/gif].include?(io.mime_type)
  end

  private

  # Helper method to process image uploads with specified dimensions
  def self.process_upload(io, width, height)
    # Handle both UploadedFile and Tempfile objects
    source_file = io.respond_to?(:download) ? io.download : io
    pipeline = ImageProcessing::MiniMagick.source(source_file)
    
    # Resize and convert to JPG
    pipeline = pipeline
      .resize_to_limit(width, height)
      .convert('jpg')
      .call
    
    # Return a File object with the correct extension
    File.open(pipeline.path, 'rb')
  end
end
