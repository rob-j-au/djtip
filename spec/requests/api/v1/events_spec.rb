require 'rails_helper'

RSpec.describe "Api::V1::Events", type: :request do
  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  def find_included_resource(type, id)
    json_response[:included]&.find { |resource| resource[:type] == type.to_s && resource[:id] == id.to_s }
  end

  describe "GET /api/v1/events" do
    let!(:events) { create_list(:event, 3) }
    let!(:users) { create_list(:user, 2, :with_event, events: [events.first]) }
    let!(:performers) { create_list(:performer, 2) }
    
    before do
      performers.each { |performer| performer.events << events.first }
    end

    it "returns all events with associated users and performers" do
      get "/api/v1/events"
      
      expect(response).to have_http_status(:ok)
      
      expect(json_response[:data]).to be_an(Array)
      expect(json_response[:data].length).to be >= 3
      
      # Find the event that has associated users and performers
      target_event = json_response[:data].find do |event|
        event[:relationships][:users][:data].length == 4 && # 2 regular users + 2 performers (since Performer inherits from User)
        event[:attributes][:performers].length == 2
      end
      
      expect(target_event).to be_present
      expect(target_event[:type]).to eq('event')
      
      # Check included resources
      expect(json_response[:included]).to be_present
      user_resources = json_response[:included].select { |resource| resource[:type] == 'user' }
      # Since performers are now custom attributes (not relationships), they won't be in included resources
      # But all users (including performers) will be in the users relationship
      expect(user_resources.length).to be >= 4 # At least 2 regular users + 2 performers (since Performer inherits from User)
    end
  end

  describe "GET /api/v1/events/:id" do
    let!(:event) { create(:event) }
    let!(:users) { create_list(:user, 2, :with_event, events: [event]) }
    let!(:performers) { create_list(:performer, 2) }
    
    before do
      performers.each { |performer| performer.events << event }
    end

    it "returns the event with associated users and performers" do
      get "/api/v1/events/#{event.id}"
      
      expect(response).to have_http_status(:ok)
      
      event_data = json_response[:data]
      expect(event_data[:type]).to eq('event')
      expect(event_data[:id]).to eq(event.id.to_s)
      expect(event_data[:attributes][:title]).to eq(event.title)
      
      # Check relationships and attributes
      expect(event_data[:relationships][:users][:data].length).to eq(4) # 2 regular users + 2 performers (since Performer inherits from User)
      expect(event_data[:attributes][:performers].length).to eq(2)
      
      # Check included resources
      expect(json_response[:included]).to be_present
      user_resources = json_response[:included].select { |resource| resource[:type] == 'user' }
      # Since performers are now custom attributes (not relationships), they won't be in included resources
      # But all users (including performers) will be in the users relationship
      expect(user_resources.length).to eq(4) # 2 regular users + 2 performers (since Performer inherits from User)
    end

    it "returns 404 for non-existent event" do
      get "/api/v1/events/nonexistent"
      
      expect(response).to have_http_status(:not_found)
      expect(json_response[:error]).to eq("Resource not found")
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
      
      event_data = json_response[:data]
      expect(event_data[:type]).to eq('event')
      expect(event_data[:attributes][:title]).to eq("Test Event")
    end

    it "returns errors with invalid attributes" do
      post "/api/v1/events", params: { event: invalid_attributes }
      
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response[:error]).to eq("Failed to create event")
      expect(json_response[:details]).to be_present
    end
  end

  describe "PUT /api/v1/events/:id" do
    let!(:event) { create(:event) }
    let(:valid_attributes) { { title: "Updated Event" } }
    let(:invalid_attributes) { { title: "" } }

    it "updates the event with valid attributes" do
      put "/api/v1/events/#{event.id}", params: { event: valid_attributes }
      
      expect(response).to have_http_status(:ok)
      
      event_data = json_response[:data]
      expect(event_data[:type]).to eq('event')
      expect(event_data[:attributes][:title]).to eq("Updated Event")
    end

    it "returns errors with invalid attributes" do
      put "/api/v1/events/#{event.id}", params: { event: invalid_attributes }
      
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response[:error]).to eq("Failed to update event")
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
