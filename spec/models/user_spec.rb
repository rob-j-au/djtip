require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create(:user) }
  
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    
    it 'validates image file type' do
      user.image = text_file
      expect(user).not_to be_valid
      expect(user.errors[:image]).to include('is not a valid image format')
    end
    
    it 'validates image file size' do
      # Create a large image (6MB)
      large_image_path = Rails.root.join('spec/fixtures/files/large_image.jpg')
      File.open(large_image_path, 'wb') do |f|
        f.write(SecureRandom.random_bytes(6 * 1024 * 1024)) # 6MB
      end
      
      user.image = Rack::Test::UploadedFile.new(large_image_path, 'image/jpeg')
      expect(user).not_to be_valid
      expect(user.errors[:image]).to include('size must be less than or equal to 5 MB')
      
      File.delete(large_image_path) if File.exist?(large_image_path)
    end
  end
  
  describe 'image upload' do
    it 'attaches an image' do
      user.image = png
      expect(user.image).to be_attached
      expect(user.image_data).to be_present
    end
    
    it 'generates versions' do
      user.image = png
      user.save!
      
      expect(user.image_url).to be_present
      expect(user.image_url(:thumb)).to be_present
      expect(user.image_url(:medium)).to be_present
    end
    
    it 'removes image when requested' do
      user.image = png
      user.save!
      
      user.remove_image = '1'
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
      expect(user.image_url(:thumb)).to include('/uploads/')
    end
  end
end
