require "shrine"
require "shrine/storage/file_system"

# For files stored locally on disk
Shrine.storages = {
  cache: Shrine::Storage::FileSystem.new("public", prefix: "uploads/cache"),
  store: Shrine::Storage::FileSystem.new("public", prefix: "uploads")
}

# For direct uploads (optional)
Shrine.plugin :upload_endpoint

# Basic plugins
Shrine.plugin :activerecord
Shrine.plugin :cached_attachment_data # for forms
Shrine.plugin :restore_cached_data
Shrine.plugin :determine_mime_type, analyzer: :mimemagic
Shrine.plugin :validation_helpers
Shrine.plugin :remove_invalid

# Image processing
Shrine.plugin :derivatives
Shrine.plugin :derivation_endpoint, prefix: "derivations"

# For direct uploads (optional)
Shrine.plugin :presign_endpoint, presign_options: -> (request) do
  # Uppy will send the "filename" with the name of the file
  filename = request.params["filename"]
  type     = request.params["type"]

  {
    content_type:        type,                  # set content type
    content_disposition: "inline; filename=#{filename}",
    content_length_range: 0..(10*1024*1024)     # limit filesize to 10MB
  }
end

# Background job plugin for processing
Shrine.plugin :backgrounding
Shrine::Attacher.promote_block do |attacher|
  ShrinePromoteJob.perform_async(
    attacher.record.class.name,
    attacher.record.id.to_s,
    attacher.name,
    attacher.file_data
  )
end

# Set up background job for promotion
Shrine::Attacher.destroy_block do |attacher|
  ShrineDestroyJob.perform_async(attacher.data)
end
