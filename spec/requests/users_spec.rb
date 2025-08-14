require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }
  
  before do
    sign_in admin
  end
  
  describe "POST /users" do
    let(:valid_attributes) do
      {
        user: {
          name: "Test User",
          email: "test@example.com",
          password: "password123",
          password_confirmation: "password123",
          image: png
        }
      }
    end
    
    it "creates a user with an image" do
      expect {
        post users_path, params: valid_attributes
      }.to change(User, :count).by(1)
      
      expect(response).to redirect_to(user_path(User.last))
      follow_redirect!
      
      expect(response.body).to include("User was successfully created.")
      expect(User.last.image).to be_attached
    end
  end
  
  describe "PATCH /users/:id" do
    let(:user) { create(:user) }
    
    context "with valid image" do
      it "updates the user's image" do
        patch user_path(user), params: {
          user: {
            image: png
          }
        }
        
        expect(response).to redirect_to(user_path(user))
        follow_redirect!
        
        expect(response.body).to include("User was successfully updated.")
        expect(user.reload.image).to be_attached
      end
    end
    
    context "when removing image" do
      before do
        user.image = png
        user.save!
      end
      
      it "removes the user's image" do
        expect(user.image).to be_attached
        
        patch user_path(user), params: {
          user: {
            remove_image: "1"
          }
        }
        
        expect(response).to redirect_to(user_path(user))
        follow_redirect!
        
        expect(response.body).to include("User was successfully updated.")
        expect(user.reload.image).not_to be_attached
      end
    end
  end
  
  describe "GET /users/:id" do
    it "shows the user's image" do
      user.image = png
      user.save!
      
      get user_path(user)
      
      expect(response).to be_successful
      expect(response.body).to include(user.image_url(:thumb))
    end
  end
end
