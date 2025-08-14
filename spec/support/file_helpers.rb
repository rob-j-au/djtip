# spec/support/file_helpers.rb
module FileHelpers
  def fixture_file_upload(path, mime_type = nil, binary = false)
    Rack::Test::UploadedFile.new(
      Rails.root.join('spec', 'fixtures', 'files', path),
      mime_type,
      binary
    )
  end

  def png_name
    'test_image.png'
  end

  def png
    fixture_file_upload(png_name, 'image/png')
  end

  def large_image
    fixture_file_upload('large_image.jpg', 'image/jpeg')
  end

  def text_file
    fixture_file_upload('test.txt', 'text/plain')
  end
end

RSpec.configure do |config|
  config.include FileHelpers, type: :model
  config.include FileHelpers, type: :request
  config.include FileHelpers, type: :feature
end
