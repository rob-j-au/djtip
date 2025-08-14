class ImageUploader < Shrine
  # Plugins for image processing and validation
  plugin :processing
  plugin :versions   # enable Shrine to handle a hash of files
  plugin :delete_raw # delete processed files after uploading
  plugin :validation_helpers
  plugin :store_dimensions
  plugin :derivation_endpoint, secret_key: Rails.application.credentials.secret_key_base

  # File validation
  Attacher.validate do
    validate_max_size 5 * 1024 * 1024, message: 'is too large (max is 5MB)'
    validate_mime_type_inclusion ['image/jpeg', 'image/png', 'image/gif']
  end

  # Process files as they're uploaded
  process(:store) do |io, _context|
    versions = { original: io }
    
    if image?(io)
      # Create thumbnail version (150x150)
      versions[:thumb] = process_upload(io, 150, 150)
      
      # Create medium version (300x300)
      versions[:medium] = process_upload(io, 300, 300)
    end
    
    versions
  end

  # Helper method to check if file is an image
  def image?(io)
    %w[image/jpeg image/png image/gif].include?(io.mime_type)
  end

  private

  # Helper method to process image uploads with specified dimensions
  def process_upload(io, width, height)
    pipeline = ImageProcessing::Vips.source(io.download)
    
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
