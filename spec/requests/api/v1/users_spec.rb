require 'rails_helper'

RSpec.describe "Api::V1::Users", type: :request do
  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  def find_included_resource(type, id)
    json_response[:included]&.find { |resource| resource[:type] == type.to_s && resource[:id] == id.to_s }
  end

  describe "GET /api/v1/users" do
    let!(:event) { create(:event) }
    let!(:users) { create_list(:user, 3, event: event) }

    it "returns all users with associated events" do
      get "/api/v1/users"
      
      expect(response).to have_http_status(:ok)
      
      expect(json_response[:data]).to be_an(Array)
      expect(json_response[:data].length).to eq(3)
      
      first_user = json_response[:data].first
      expect(first_user[:type]).to eq('user')
      expect(first_user[:relationships][:event][:data][:id]).to eq(event.id.to_s)
      
      # Check included resources
      expect(json_response[:included]).to be_present
      event_resource = find_included_resource(:event, event.id)
      expect(event_resource[:attributes][:title]).to eq(event.title)
    end
  end

  describe "GET /api/v1/users/:id" do
    let!(:event) { create(:event) }
    let!(:user) { create(:user, event: event) }

    it "returns the user with associated event" do
      get "/api/v1/users/#{user.id}"
      
      expect(response).to have_http_status(:ok)
      
      user_data = json_response[:data]
      expect(user_data[:type]).to eq('user')
      expect(user_data[:id]).to eq(user.id.to_s)
      expect(user_data[:attributes][:name]).to eq(user.name)
      
      # Check relationships
      expect(user_data[:relationships][:event][:data][:id]).to eq(event.id.to_s)
      
      # Check included resources
      event_resource = find_included_resource(:event, event.id)
      expect(event_resource[:attributes][:title]).to eq(event.title)
    end

    it "returns 404 for non-existent user" do
      get "/api/v1/users/nonexistent"
      
      expect(response).to have_http_status(:not_found)
      expect(json_response[:error]).to eq("Resource not found")
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
      
      user_data = json_response[:data]
      expect(user_data[:type]).to eq('user')
      expect(user_data[:attributes][:name]).to eq("John Doe")
      expect(user_data[:relationships][:event][:data][:id]).to eq(event.id.to_s)
      
      # Check included resources
      event_resource = find_included_resource(:event, event.id)
      expect(event_resource[:attributes][:title]).to eq(event.title)
    end

    it "returns errors with invalid attributes" do
      post "/api/v1/users", params: { user: invalid_attributes }
      
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response[:error]).to eq("Failed to create user")
      expect(json_response[:details]).to be_present
    end
  end

  describe "PUT /api/v1/users/:id" do
    let!(:user) { create(:user) }
    let(:valid_attributes) { { name: "Updated Name" } }
    let(:invalid_attributes) { { email: "invalid-email" } }

    it "updates the user with valid attributes" do
      put "/api/v1/users/#{user.id}", params: { user: valid_attributes }
      
      expect(response).to have_http_status(:ok)
      
      user_data = json_response[:data]
      expect(user_data[:type]).to eq('user')
      expect(user_data[:attributes][:name]).to eq("Updated Name")
    end

    it "returns errors with invalid attributes" do
      put "/api/v1/users/#{user.id}", params: { user: invalid_attributes }
      
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response[:error]).to eq("Failed to update user")
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
