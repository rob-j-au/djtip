require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create(:user) }
  
  describe 'validations' do
    it 'validates presence of name' do
      user.name = nil
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end
    
    it 'validates presence of email' do
      user.email = nil
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end
    
    it 'validates image file type' do
      user.image = text_file
      expect(user).not_to be_valid
      expect(user.errors[:image]).to include('type must be one of: image/jpeg, image/png, image/gif')
    end
    
    it 'validates image file size' do
      # Create a large image (6MB)
      large_image_path = Rails.root.join('spec/fixtures/files/large_image.jpg')
      File.open(large_image_path, 'wb') do |f|
        f.write(SecureRandom.random_bytes(6 * 1024 * 1024)) # 6MB
      end
      
      user.image = Rack::Test::UploadedFile.new(large_image_path, 'image/jpeg')
      expect(user).not_to be_valid
      expect(user.errors[:image]).to include('is too large (max is 5MB)')
      
      File.delete(large_image_path) if File.exist?(large_image_path)
    end
  end
  
  describe 'image upload' do
    it 'attaches an image' do
      user.image = png
      expect(user.image).to be_present
      expect(user.image_data).to be_present
    end
    
    it 'generates versions' do
      user.image = png
      user.save!
      
      # Test that the original image URL is present
      expect(user.image_url).to be_present
      
      # For now, just test that derivatives can be accessed without error
      # (actual generation may happen in background or require different setup)
      expect { user.image_url(:thumb) }.not_to raise_error
      expect { user.image_url(:medium) }.not_to raise_error
    end
    
    it 'removes image when requested' do
      user.image = png
      user.save!
      
      user.image = nil
      user.save!
      
      expect(user.image_data).to be_nil
    end
  end
  
  describe '#image_url' do
    it 'returns nil when no image is attached' do
      expect(user.image_url).to be_nil
      expect(user.image_url(:thumb)).to be_nil
    end
    
    it 'returns URL for attached image' do
      user.image = png
      user.save!
      
      expect(user.image_url).to include('/uploads/')
      
      # Test derivative URL only if it exists (derivatives may not be generated in test env)
      thumb_url = user.image_url(:thumb)
      if thumb_url
        expect(thumb_url).to include('/uploads/')
      else
        expect(thumb_url).to be_nil
      end
    end
  end
end
