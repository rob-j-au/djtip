require 'rails_helper'

RSpec.describe "Api::V1::Performances", type: :request do
  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  describe "GET /api/v1/performances" do
    let!(:performer) { create(:performer) }
    let!(:event) { create(:event) }
    let!(:performances) { create_list(:performance, 3, performer: performer, event: event) }

    it "returns all performances with associated performers and events" do
      get "/api/v1/performances"
      
      expect(response).to have_http_status(:ok)
      
      expect(json_response[:data]).to be_an(Array)
      expect(json_response[:data].length).to eq(3)
      
      performance = json_response[:data].first
      expect(performance[:type]).to eq('performance')
      expect(performance[:attributes][:time]).to be_present
      expect(performance[:attributes][:location]).to be_an(Array)
      expect(performance[:attributes][:latitude]).to be_present
      expect(performance[:attributes][:longitude]).to be_present
      
      expect(performance[:relationships][:performer][:data][:id]).to eq(performer.id.to_s)
      expect(performance[:relationships][:event][:data][:id]).to eq(event.id.to_s)
      
      expect(json_response[:included]).to be_present
    end
  end

  describe "GET /api/v1/performances/:id" do
    let!(:performer) { create(:performer) }
    let!(:event) { create(:event) }
    let!(:performance) { create(:performance, performer: performer, event: event) }

    it "returns the performance with associated performer and event" do
      get "/api/v1/performances/#{performance.id}"
      
      expect(response).to have_http_status(:ok)
      
      performance_data = json_response[:data]
      expect(performance_data[:type]).to eq('performance')
      expect(performance_data[:id]).to eq(performance.id.to_s)
      expect(performance_data[:attributes][:time]).to be_present
      expect(performance_data[:attributes][:location]).to be_an(Array)
      expect(performance_data[:attributes][:latitude]).to eq(performance.latitude)
      expect(performance_data[:attributes][:longitude]).to eq(performance.longitude)
      
      expect(performance_data[:relationships][:performer][:data][:id]).to eq(performer.id.to_s)
      expect(performance_data[:relationships][:event][:data][:id]).to eq(event.id.to_s)
      
      expect(json_response[:included]).to be_present
    end

    it "returns 404 for non-existent performance" do
      get "/api/v1/performances/nonexistent"
      
      expect(response).to have_http_status(:not_found)
      expect(json_response[:error]).to eq("Resource not found")
    end
  end

  describe "POST /api/v1/performances" do
    let!(:performer) { create(:performer) }
    let!(:event) { create(:event) }
    
    let(:valid_attributes) do
      {
        time: 1.week.from_now,
        latitude: -33.8688,
        longitude: 151.2093,
        performer_id: performer.id.to_s,
        event_id: event.id.to_s
      }
    end

    let(:invalid_attributes) do
      {
        time: nil,
        performer_id: performer.id.to_s,
        event_id: event.id.to_s
      }
    end

    it "creates a new performance with valid attributes" do
      expect {
        post "/api/v1/performances", params: { performance: valid_attributes }
      }.to change(Performance, :count).by(1)
      
      expect(response).to have_http_status(:created)
      
      performance_data = json_response[:data]
      expect(performance_data[:type]).to eq('performance')
      expect(performance_data[:attributes][:latitude]).to eq(-33.8688)
      expect(performance_data[:attributes][:longitude]).to eq(151.2093)
    end

    it "returns errors with invalid attributes" do
      post "/api/v1/performances", params: { performance: invalid_attributes }
      
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response[:error]).to eq("Failed to create performance")
      expect(json_response[:details]).to be_present
    end
  end

  describe "PUT /api/v1/performances/:id" do
    let!(:performer) { create(:performer) }
    let!(:event) { create(:event) }
    let!(:performance) { create(:performance, performer: performer, event: event) }
    
    let(:valid_attributes) do
      { 
        time: 2.weeks.from_now,
        latitude: -37.8136,
        longitude: 144.9631
      }
    end
    
    let(:invalid_attributes) { { time: nil } }

    it "updates the performance with valid attributes" do
      put "/api/v1/performances/#{performance.id}", params: { performance: valid_attributes }
      
      expect(response).to have_http_status(:ok)
      
      performance_data = json_response[:data]
      expect(performance_data[:type]).to eq('performance')
      expect(performance_data[:attributes][:latitude]).to eq(-37.8136)
      expect(performance_data[:attributes][:longitude]).to eq(144.9631)
    end

    it "returns errors with invalid attributes" do
      put "/api/v1/performances/#{performance.id}", params: { performance: invalid_attributes }
      
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response[:error]).to eq("Failed to update performance")
    end
  end

  describe "DELETE /api/v1/performances/:id" do
    let!(:performance) { create(:performance) }

    it "deletes the performance" do
      expect {
        delete "/api/v1/performances/#{performance.id}"
      }.to change(Performance, :count).by(-1)
      
      expect(response).to have_http_status(:no_content)
    end
  end
end
