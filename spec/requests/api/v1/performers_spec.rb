require 'rails_helper'

RSpec.describe "Api::V1::Performers", type: :request do
  describe "GET /api/v1/performers" do
    let!(:event) { create(:event) }
    let!(:performers) { create_list(:performer, 3, event: event) }

    it "returns all performers with associated events" do
      get "/api/v1/performers"
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      
      expect(json_response.length).to eq(3)
      expect(json_response.first).to have_key("event")
      expect(json_response.first["event"]["title"]).to eq(event.title)
    end
  end

  describe "GET /api/v1/performers/:id" do
    let!(:event) { create(:event) }
    let!(:performer) { create(:performer, event: event) }

    it "returns the performer with associated event" do
      get "/api/v1/performers/#{performer.id}"
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      
      expect(json_response["name"]).to eq(performer.name)
      expect(json_response["event"]["title"]).to eq(event.title)
    end

    it "returns 404 for non-existent performer" do
      get "/api/v1/performers/nonexistent"
      
      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)
      expect(json_response["error"]).to eq("Resource not found")
    end
  end

  describe "POST /api/v1/performers" do
    let!(:event) { create(:event) }
    let(:valid_attributes) do
      {
        name: "DJ Test",
        bio: "A test DJ",
        genre: "Electronic",
        contact: "dj@example.com",
        event_id: event.id
      }
    end

    let(:invalid_attributes) do
      {
        name: "",
        genre: ""
      }
    end

    it "creates a new performer with valid attributes" do
      expect {
        post "/api/v1/performers", params: { performer: valid_attributes }
      }.to change(Performer, :count).by(1)
      
      expect(response).to have_http_status(:created)
      json_response = JSON.parse(response.body)
      expect(json_response["name"]).to eq("DJ Test")
      expect(json_response["event"]["id"]).to eq(event.id.to_s)
    end

    it "returns errors with invalid attributes" do
      post "/api/v1/performers", params: { performer: invalid_attributes }
      
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response["error"]).to eq("Failed to create performer")
      expect(json_response["details"]).to be_present
    end
  end

  describe "PUT /api/v1/performers/:id" do
    let!(:performer) { create(:performer) }
    let(:valid_attributes) { { name: "Updated DJ" } }
    let(:invalid_attributes) { { name: "" } }

    it "updates the performer with valid attributes" do
      put "/api/v1/performers/#{performer.id}", params: { performer: valid_attributes }
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response["name"]).to eq("Updated DJ")
    end

    it "returns errors with invalid attributes" do
      put "/api/v1/performers/#{performer.id}", params: { performer: invalid_attributes }
      
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response["error"]).to eq("Failed to update performer")
    end
  end

  describe "DELETE /api/v1/performers/:id" do
    let!(:performer) { create(:performer) }

    it "deletes the performer" do
      expect {
        delete "/api/v1/performers/#{performer.id}"
      }.to change(Performer, :count).by(-1)
      
      expect(response).to have_http_status(:no_content)
    end
  end
end
