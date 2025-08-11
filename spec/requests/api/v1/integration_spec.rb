require 'rails_helper'

RSpec.describe "API Integration Tests", type: :request do
  describe "Event with Users and Performers workflow" do
    let!(:event) { create(:event, title: "DJ Night") }
    let!(:user1) { create(:user, name: "John Doe", event: event) }
    let!(:user2) { create(:user, name: "Jane Smith", event: event) }
    let!(:performer1) { create(:performer, name: "DJ Alpha", genre: "House", event: event) }
    let!(:performer2) { create(:performer, name: "DJ Beta", genre: "Techno", event: event) }

    it "returns complete event data with all associated users and performers" do
      get "/api/v1/events/#{event.id}"
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      
      # Verify event data
      expect(json_response["title"]).to eq("DJ Night")
      
      # Verify users are included
      expect(json_response["users"]).to be_present
      expect(json_response["users"].length).to eq(2)
      user_names = json_response["users"].map { |u| u["name"] }
      expect(user_names).to include("John Doe", "Jane Smith")
      
      # Verify performers are included
      expect(json_response["performers"]).to be_present
      expect(json_response["performers"].length).to eq(2)
      performer_names = json_response["performers"].map { |p| p["name"] }
      expect(performer_names).to include("DJ Alpha", "DJ Beta")
    end

    it "allows creating a new user for an existing event via API" do
      user_params = {
        name: "New User",
        email: "newuser@example.com",
        phone: "555-1234",
        event_id: event.id
      }

      expect {
        post "/api/v1/users", params: { user: user_params }
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      json_response = JSON.parse(response.body)
      expect(json_response["name"]).to eq("New User")
      expect(json_response["event"]["id"]).to eq(event.id.to_s)

      # Verify the user is now associated with the event
      get "/api/v1/events/#{event.id}"
      event_response = JSON.parse(response.body)
      expect(event_response["users"].length).to eq(3)
    end

    it "allows creating a new performer for an existing event via API" do
      performer_params = {
        name: "DJ Gamma",
        bio: "New DJ on the scene",
        genre: "Drum & Bass",
        contact: "djgamma@example.com",
        event_id: event.id
      }

      expect {
        post "/api/v1/performers", params: { performer: performer_params }
      }.to change(Performer, :count).by(1)

      expect(response).to have_http_status(:created)
      json_response = JSON.parse(response.body)
      expect(json_response["name"]).to eq("DJ Gamma")
      expect(json_response["event"]["id"]).to eq(event.id.to_s)

      # Verify the performer is now associated with the event
      get "/api/v1/events/#{event.id}"
      event_response = JSON.parse(response.body)
      expect(event_response["performers"].length).to eq(3)
    end

    it "handles cascading deletes when event is deleted" do
      event_id = event.id
      user_count = User.where(event_id: event_id).count
      performer_count = Performer.where(event_id: event_id).count

      expect(user_count).to eq(2)
      expect(performer_count).to eq(2)

      delete "/api/v1/events/#{event_id}"
      expect(response).to have_http_status(:no_content)

      # Verify associated users and performers are also deleted
      expect(User.where(event_id: event_id).count).to eq(0)
      expect(Performer.where(event_id: event_id).count).to eq(0)
    end
  end

  describe "API Error Handling" do
    it "returns proper error format for validation failures" do
      post "/api/v1/events", params: { event: { title: "" } }
      
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      
      expect(json_response).to have_key("error")
      expect(json_response).to have_key("details")
      expect(json_response["error"]).to eq("Failed to create event")
      expect(json_response["details"]).to be_an(Array)
    end

    it "returns 404 for non-existent resources" do
      get "/api/v1/events/nonexistent"
      
      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)
      expect(json_response["error"]).to eq("Resource not found")
    end
  end

  describe "API Content Types" do
    it "returns JSON by default for API endpoints" do
      event = create(:event)
      get "/api/v1/events/#{event.id}"
      
      expect(response.content_type).to include("application/json")
    end

    it "accepts JSON payloads for POST requests" do
      event_params = {
        title: "JSON Event",
        description: "Created via JSON",
        date: Time.current + 1.week,
        location: "JSON Location"
      }

      post "/api/v1/events", 
           params: { event: event_params }.to_json,
           headers: { 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:created)
      json_response = JSON.parse(response.body)
      expect(json_response["title"]).to eq("JSON Event")
    end
  end
end
