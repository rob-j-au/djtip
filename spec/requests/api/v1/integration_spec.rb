require 'rails_helper'

RSpec.describe "API Integration Tests", type: :request do
  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  def find_included_resource(type, id)
    json_response[:included]&.find { |resource| resource[:type] == type.to_s && resource[:id] == id.to_s }
  end

  describe "Event with Users and Performers workflow" do
    let!(:event) { create(:event, title: "DJ Night") }
    let!(:user1) { create(:user, :with_event, name: "John Doe", events: [event]) }
    let!(:user2) { create(:user, :with_event, name: "Jane Smith", events: [event]) }
    let!(:performer1) { create(:performer, name: "DJ Alpha", genre: "House", events: [event]) }
    let!(:performer2) { create(:performer, name: "DJ Beta", genre: "Techno", events: [event]) }

    it "returns complete event data with all associated users and performers" do
      get "/api/v1/events/#{event.id}"
      
      expect(response).to have_http_status(:ok)
      
      # Verify event data
      event_data = json_response[:data]
      expect(event_data[:type]).to eq('event')
      expect(event_data[:attributes][:title]).to eq("DJ Night")
      
      # Verify relationships and attributes
      expect(event_data[:relationships][:users][:data].length).to eq(4) # 2 regular users + 2 performers (since Performer inherits from User)
      expect(event_data[:attributes][:performers].length).to eq(2)
      
      # Verify included resources
      expect(json_response[:included]).to be_present
      user_resources = json_response[:included].select { |resource| resource[:type] == 'user' }
      # Since performers are now custom attributes (not relationships), they won't be in included resources
      # But all users (including performers) will be in the users relationship
      expect(user_resources.length).to eq(4) # 2 regular users + 2 performers (since Performer inherits from User)
      user_names = user_resources.map { |u| u[:attributes][:name] }
      expect(user_names).to include("John Doe", "Jane Smith")
      
      # Verify performers are in the custom attributes
      performer_names = event_data[:attributes][:performers].map { |p| p[:name] }
      expect(performer_names).to include("DJ Alpha", "DJ Beta")
    end

    it "allows creating a new user for an existing event via API" do
      user_params = {
        name: "New User",
        email: "newuser@example.com",
        phone: "555-1234",
        password: "password123",
        password_confirmation: "password123",
        event_ids: [event.id]
      }

      expect {
        post "/api/v1/users", params: { user: user_params }
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      
      user_data = json_response[:data]
      expect(user_data[:type]).to eq('user')
      expect(user_data[:attributes][:name]).to eq("New User")
      expect(user_data[:relationships][:events][:data]).to be_an(Array)
      expect(user_data[:relationships][:events][:data].first[:id]).to eq(event.id.to_s)

      # Verify the user is now associated with the event
      get "/api/v1/events/#{event.id}"
      expect(json_response[:data][:relationships][:users][:data].length).to eq(5) # 3 regular users + 2 performers (since Performer inherits from User)
    end

    it "allows creating a new performer for an existing event via API" do
      performer_params = {
        name: "DJ Gamma",
        email: "djgamma@example.com",
        password: "password123",
        password_confirmation: "password123",
        bio: "New DJ on the scene",
        genre: "Drum & Bass",
        contact: "djgamma@example.com",
        event_ids: [event.id]
      }

      expect {
        post "/api/v1/performers", params: { performer: performer_params }
      }.to change(Performer, :count).by(1)

      expect(response).to have_http_status(:created)
      
      performer_data = json_response[:data]
      expect(performer_data[:type]).to eq('performer')
      expect(performer_data[:attributes][:name]).to eq("DJ Gamma")
      expect(performer_data[:relationships][:events][:data]).to be_present
      expect(performer_data[:relationships][:events][:data].first[:id]).to eq(event.id.to_s)

      # Verify the performer is now associated with the event
      get "/api/v1/events/#{event.id}"
      expect(json_response[:data][:attributes][:performers].length).to eq(3)
    end

    it "handles cascading deletes when event is deleted" do
      event_id = event.id
      user_count = event.users.count
      performer_count = event.performers.count

      expect(user_count).to eq(4) # 2 regular users + 2 performers (since Performer inherits from User)
      expect(performer_count).to eq(2)

      delete "/api/v1/events/#{event_id}"
      expect(response).to have_http_status(:no_content)

      # Verify event is deleted
      expect(Event.where(id: event_id).count).to eq(0)
      
      # Verify performers still exist (they use many-to-many association now, not dependent: :destroy)
      expect(Performer.count).to eq(2)  # Performers still exist
      
      # Users are not deleted with many-to-many association
      expect(User.count).to eq(4)  # All users (including performers) still exist
      
      # Verify the deleted event no longer exists in the system
      get "/api/v1/events/#{event_id}"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "API Error Handling" do
    it "returns proper error format for validation failures" do
      post "/api/v1/events", params: { event: { title: "" } }
      
      expect(response).to have_http_status(:unprocessable_content)
      
      expect(json_response).to have_key(:error)
      expect(json_response).to have_key(:details)
      expect(json_response[:error]).to eq("Failed to create event")
      expect(json_response[:details]).to be_an(Array)
    end

    it "returns 404 for non-existent resources" do
      get "/api/v1/events/nonexistent"
      
      expect(response).to have_http_status(:not_found)
      expect(json_response[:error]).to eq("Resource not found")
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
      
      event_data = json_response[:data]
      expect(event_data[:type]).to eq('event')
      expect(event_data[:attributes][:title]).to eq("JSON Event")
    end
  end
end
