require 'rails_helper'

RSpec.describe "Api::V1::Events", type: :request do
  describe "GET /api/v1/events" do
    let!(:events) { create_list(:event, 3) }
    let!(:users) { create_list(:user, 2, event: events.first) }
    let!(:performers) { create_list(:performer, 2, event: events.first) }

    it "returns all events with associated users and performers" do
      get "/api/v1/events"
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      
      expect(json_response.length).to eq(3)
      expect(json_response.first).to have_key("users")
      expect(json_response.first).to have_key("performers")
      expect(json_response.first["users"].length).to eq(2)
      expect(json_response.first["performers"].length).to eq(2)
    end
  end

  describe "GET /api/v1/events/:id" do
    let!(:event) { create(:event) }
    let!(:users) { create_list(:user, 2, event: event) }
    let!(:performers) { create_list(:performer, 2, event: event) }

    it "returns the event with associated users and performers" do
      get "/api/v1/events/#{event.id}"
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      
      expect(json_response["title"]).to eq(event.title)
      expect(json_response["users"].length).to eq(2)
      expect(json_response["performers"].length).to eq(2)
    end

    it "returns 404 for non-existent event" do
      get "/api/v1/events/nonexistent"
      
      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)
      expect(json_response["error"]).to eq("Resource not found")
    end
  end

  describe "POST /api/v1/events" do
    let(:valid_attributes) do
      {
        title: "Test Event",
        description: "A test event",
        date: Time.current + 1.week,
        location: "Test Location"
      }
    end

    let(:invalid_attributes) do
      {
        title: "",
        description: "A test event"
      }
    end

    it "creates a new event with valid attributes" do
      expect {
        post "/api/v1/events", params: { event: valid_attributes }
      }.to change(Event, :count).by(1)
      
      expect(response).to have_http_status(:created)
      json_response = JSON.parse(response.body)
      expect(json_response["title"]).to eq("Test Event")
    end

    it "returns errors with invalid attributes" do
      post "/api/v1/events", params: { event: invalid_attributes }
      
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response["error"]).to eq("Failed to create event")
      expect(json_response["details"]).to be_present
    end
  end

  describe "PUT /api/v1/events/:id" do
    let!(:event) { create(:event) }
    let(:valid_attributes) { { title: "Updated Event" } }
    let(:invalid_attributes) { { title: "" } }

    it "updates the event with valid attributes" do
      put "/api/v1/events/#{event.id}", params: { event: valid_attributes }
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response["title"]).to eq("Updated Event")
    end

    it "returns errors with invalid attributes" do
      put "/api/v1/events/#{event.id}", params: { event: invalid_attributes }
      
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response["error"]).to eq("Failed to update event")
    end
  end

  describe "DELETE /api/v1/events/:id" do
    let!(:event) { create(:event) }

    it "deletes the event" do
      expect {
        delete "/api/v1/events/#{event.id}"
      }.to change(Event, :count).by(-1)
      
      expect(response).to have_http_status(:no_content)
    end
  end
end
