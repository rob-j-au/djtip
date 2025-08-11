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
    let!(:user1) { create(:user, name: "John Doe", event: event) }
    let!(:user2) { create(:user, name: "Jane Smith", event: event) }
    let!(:performer1) { create(:performer, name: "DJ Alpha", genre: "House", event: event) }
    let!(:performer2) { create(:performer, name: "DJ Beta", genre: "Techno", event: event) }

    it "returns complete event data with all associated users and performers" do
      get "/api/v1/events/#{event.id}"
      
      expect(response).to have_http_status(:ok)
      
      # Verify event data
      event_data = json_response[:data]
      expect(event_data[:type]).to eq('event')
      expect(event_data[:attributes][:title]).to eq("DJ Night")
      
      # Verify relationships
      expect(event_data[:relationships][:users][:data].length).to eq(2)
      expect(event_data[:relationships][:performers][:data].length).to eq(2)
      
      # Verify included resources
      expect(json_response[:included]).to be_present
      user_resources = json_response[:included].select { |resource| resource[:type] == 'user' }
      performer_resources = json_response[:included].select { |resource| resource[:type] == 'performer' }
      
      expect(user_resources.length).to eq(2)
      user_names = user_resources.map { |u| u[:attributes][:name] }
      expect(user_names).to include("John Doe", "Jane Smith")
      
      expect(performer_resources.length).to eq(2)
      performer_names = performer_resources.map { |p| p[:attributes][:name] }
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
      
      user_data = json_response[:data]
      expect(user_data[:type]).to eq('user')
      expect(user_data[:attributes][:name]).to eq("New User")
      expect(user_data[:relationships][:event][:data][:id]).to eq(event.id.to_s)

      # Verify the user is now associated with the event
      get "/api/v1/events/#{event.id}"
      expect(json_response[:data][:relationships][:users][:data].length).to eq(3)
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
      
      performer_data = json_response[:data]
      expect(performer_data[:type]).to eq('performer')
      expect(performer_data[:attributes][:name]).to eq("DJ Gamma")
      expect(performer_data[:relationships][:event][:data][:id]).to eq(event.id.to_s)

      # Verify the performer is now associated with the event
      get "/api/v1/events/#{event.id}"
      expect(json_response[:data][:relationships][:performers][:data].length).to eq(3)
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
