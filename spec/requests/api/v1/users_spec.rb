require 'rails_helper'

RSpec.describe "Api::V1::Users", type: :request do
  describe "GET /api/v1/users" do
    let!(:event) { create(:event) }
    let!(:users) { create_list(:user, 3, event: event) }

    it "returns all users with associated events" do
      get "/api/v1/users"
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      
      expect(json_response.length).to eq(3)
      expect(json_response.first).to have_key("event")
      expect(json_response.first["event"]["title"]).to eq(event.title)
    end
  end

  describe "GET /api/v1/users/:id" do
    let!(:event) { create(:event) }
    let!(:user) { create(:user, event: event) }

    it "returns the user with associated event" do
      get "/api/v1/users/#{user.id}"
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      
      expect(json_response["name"]).to eq(user.name)
      expect(json_response["event"]["title"]).to eq(event.title)
    end

    it "returns 404 for non-existent user" do
      get "/api/v1/users/nonexistent"
      
      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)
      expect(json_response["error"]).to eq("Resource not found")
    end
  end

  describe "POST /api/v1/users" do
    let!(:event) { create(:event) }
    let(:valid_attributes) do
      {
        name: "John Doe",
        email: "john@example.com",
        phone: "123-456-7890",
        event_id: event.id
      }
    end

    let(:invalid_attributes) do
      {
        name: "",
        email: "invalid-email"
      }
    end

    it "creates a new user with valid attributes" do
      expect {
        post "/api/v1/users", params: { user: valid_attributes }
      }.to change(User, :count).by(1)
      
      expect(response).to have_http_status(:created)
      json_response = JSON.parse(response.body)
      expect(json_response["name"]).to eq("John Doe")
      expect(json_response["event"]["id"]).to eq(event.id.to_s)
    end

    it "returns errors with invalid attributes" do
      post "/api/v1/users", params: { user: invalid_attributes }
      
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response["error"]).to eq("Failed to create user")
      expect(json_response["details"]).to be_present
    end
  end

  describe "PUT /api/v1/users/:id" do
    let!(:user) { create(:user) }
    let(:valid_attributes) { { name: "Updated Name" } }
    let(:invalid_attributes) { { email: "invalid-email" } }

    it "updates the user with valid attributes" do
      put "/api/v1/users/#{user.id}", params: { user: valid_attributes }
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response["name"]).to eq("Updated Name")
    end

    it "returns errors with invalid attributes" do
      put "/api/v1/users/#{user.id}", params: { user: invalid_attributes }
      
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response["error"]).to eq("Failed to update user")
    end
  end

  describe "DELETE /api/v1/users/:id" do
    let!(:user) { create(:user) }

    it "deletes the user" do
      expect {
        delete "/api/v1/users/#{user.id}"
      }.to change(User, :count).by(-1)
      
      expect(response).to have_http_status(:no_content)
    end
  end
end
