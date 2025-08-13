require 'rails_helper'

RSpec.describe "Api::V1::Performers", type: :request do
  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  def find_included_resource(type, id)
    json_response[:included]&.find { |resource| resource[:type] == type.to_s && resource[:id] == id.to_s }
  end

  describe "GET /api/v1/performers" do
    let!(:event) { create(:event) }
    let!(:performers) { create_list(:performer, 3, event: event) }

    it "returns all performers with associated events" do
      get "/api/v1/performers"
      
      expect(response).to have_http_status(:ok)
      
      expect(json_response[:data]).to be_an(Array)
      expect(json_response[:data].length).to eq(3)
      
      first_performer = json_response[:data].first
      expect(first_performer[:type]).to eq('performer')
      expect(first_performer[:relationships][:event][:data][:id]).to eq(event.id.to_s)
      
      # Check included resources
      expect(json_response[:included]).to be_present
      event_resource = find_included_resource(:event, event.id)
      expect(event_resource[:attributes][:title]).to eq(event.title)
    end
  end

  describe "GET /api/v1/performers/:id" do
    let!(:event) { create(:event) }
    let!(:performer) { create(:performer, event: event) }

    it "returns the performer with associated event" do
      get "/api/v1/performers/#{performer.id}"
      
      expect(response).to have_http_status(:ok)
      
      performer_data = json_response[:data]
      expect(performer_data[:type]).to eq('performer')
      expect(performer_data[:id]).to eq(performer.id.to_s)
      expect(performer_data[:attributes][:name]).to eq(performer.name)
      
      # Check relationships
      expect(performer_data[:relationships][:event][:data][:id]).to eq(event.id.to_s)
      
      # Check included resources
      event_resource = find_included_resource(:event, event.id)
      expect(event_resource[:attributes][:title]).to eq(event.title)
    end

    it "returns 404 for non-existent performer" do
      get "/api/v1/performers/nonexistent"
      
      expect(response).to have_http_status(:not_found)
      expect(json_response[:error]).to eq("Resource not found")
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
      
      performer_data = json_response[:data]
      expect(performer_data[:type]).to eq('performer')
      expect(performer_data[:attributes][:name]).to eq("DJ Test")
      expect(performer_data[:relationships][:event][:data][:id]).to eq(event.id.to_s)
      
      # Check included resources
      event_resource = find_included_resource(:event, event.id)
      expect(event_resource[:attributes][:title]).to eq(event.title)
    end

    it "returns errors with invalid attributes" do
      post "/api/v1/performers", params: { performer: invalid_attributes }
      
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response[:error]).to eq("Failed to create performer")
      expect(json_response[:details]).to be_present
    end
  end

  describe "PUT /api/v1/performers/:id" do
    let!(:performer) { create(:performer) }
    let(:valid_attributes) { { name: "Updated DJ" } }
    let(:invalid_attributes) { { name: "" } }

    it "updates the performer with valid attributes" do
      put "/api/v1/performers/#{performer.id}", params: { performer: valid_attributes }
      
      expect(response).to have_http_status(:ok)
      
      performer_data = json_response[:data]
      expect(performer_data[:type]).to eq('performer')
      expect(performer_data[:attributes][:name]).to eq("Updated DJ")
    end

    it "returns errors with invalid attributes" do
      put "/api/v1/performers/#{performer.id}", params: { performer: invalid_attributes }
      
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response[:error]).to eq("Failed to update performer")
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
