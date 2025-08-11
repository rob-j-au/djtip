require 'rails_helper'

RSpec.describe "/api/v1/events/:event_id/tips", type: :request do
  let(:event) { create(:event) }
  let(:user) { create(:user) }
  let(:tip) { create(:tip, event: event, user: user) }

  let(:valid_attributes) {
    {
      amount: 25.50,
      currency: 'USD',
      message: 'Great performance!',
      user_id: user.id
    }
  }

  let(:invalid_attributes) {
    {
      amount: nil,
      currency: '',
      user_id: nil
    }
  }

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  def find_included_resource(type, id)
    json_response[:included]&.find { |resource| resource[:type] == type.to_s && resource[:id] == id.to_s }
  end

  describe "GET /api/v1/events/:event_id/tips" do
    it "returns all tips for the event with associated users" do
      tip # create the tip
      get "/api/v1/events/#{event.id}/tips"
      
      expect(response).to have_http_status(:ok)
      expect(json_response[:data]).to be_an(Array)
      
      tip_data = json_response[:data].first
      expect(tip_data[:type]).to eq('tip')
      expect(tip_data[:id]).to eq(tip.id.to_s)
      expect(tip_data[:attributes][:amount]).to eq('25.5')
      expect(tip_data[:attributes][:currency]).to eq('USD')
      expect(tip_data[:attributes][:message]).to eq('Great performance! Keep it up!')
      
      # Check relationships
      expect(tip_data[:relationships][:event][:data][:id]).to eq(event.id.to_s)
      expect(tip_data[:relationships][:user][:data][:id]).to eq(user.id.to_s)
      
      # Check included resources
      event_resource = find_included_resource(:event, event.id)
      expect(event_resource[:attributes][:title]).to eq(event.title)
      
      user_resource = find_included_resource(:user, user.id)
      expect(user_resource[:attributes][:name]).to eq(user.name)
    end
  end

  describe "GET /api/v1/events/:event_id/tips/:id" do
    it "returns the tip with associated event and user" do
      get "/api/v1/events/#{event.id}/tips/#{tip.id}"
      
      expect(response).to have_http_status(:ok)
      
      tip_data = json_response[:data]
      expect(tip_data[:type]).to eq('tip')
      expect(tip_data[:id]).to eq(tip.id.to_s)
      expect(tip_data[:attributes][:amount]).to eq('25.5')
      expect(tip_data[:attributes][:currency]).to eq('USD')
      expect(tip_data[:attributes][:message]).to eq('Great performance! Keep it up!')
      
      # Check relationships
      expect(tip_data[:relationships][:event][:data][:id]).to eq(event.id.to_s)
      expect(tip_data[:relationships][:user][:data][:id]).to eq(user.id.to_s)
      
      # Check included resources
      event_resource = find_included_resource(:event, event.id)
      expect(event_resource[:attributes][:title]).to eq(event.title)
      
      user_resource = find_included_resource(:user, user.id)
      expect(user_resource[:attributes][:name]).to eq(user.name)
    end

    it "returns 404 for non-existent tip" do
      get "/api/v1/events/#{event.id}/tips/nonexistent"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/events/:event_id/tips" do
    context "with valid parameters" do
      it "creates a new tip" do
        expect {
          post "/api/v1/events/#{event.id}/tips", params: { tip: valid_attributes }
        }.to change(Tip, :count).by(1)
        
        expect(response).to have_http_status(:created)
        
        tip_data = json_response[:data]
        expect(tip_data[:type]).to eq('tip')
        expect(tip_data[:attributes][:amount]).to eq('25.5')
        expect(tip_data[:attributes][:currency]).to eq('USD')
        expect(tip_data[:attributes][:message]).to eq('Great performance!')
        
        # Check relationships
        expect(tip_data[:relationships][:event][:data][:id]).to eq(event.id.to_s)
        expect(tip_data[:relationships][:user][:data][:id]).to eq(user.id.to_s)
        
        # Check included resources
        event_resource = find_included_resource(:event, event.id)
        expect(event_resource[:attributes][:title]).to eq(event.title)
        
        user_resource = find_included_resource(:user, user.id)
        expect(user_resource[:attributes][:name]).to eq(user.name)
      end
    end

    context "with invalid parameters" do
      it "does not create a new tip" do
        expect {
          post "/api/v1/events/#{event.id}/tips", params: { tip: invalid_attributes }
        }.to change(Tip, :count).by(0)
        
        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response[:error]).to eq("Failed to create tip")
      end
    end
  end

  describe "PUT /api/v1/events/:event_id/tips/:id" do
    it "updates the tip with valid attributes" do
      put "/api/v1/events/#{event.id}/tips/#{tip.id}", params: { 
        tip: { amount: 50.00, message: "Updated message" } 
      }
      
      expect(response).to have_http_status(:ok)
      
      tip_data = json_response[:data]
      expect(tip_data[:type]).to eq('tip')
      expect(tip_data[:attributes][:amount]).to eq('50.0')
      expect(tip_data[:attributes][:message]).to eq('Updated message')
      
      # Check relationships
      expect(tip_data[:relationships][:event][:data][:id]).to eq(event.id.to_s)
      expect(tip_data[:relationships][:user][:data][:id]).to eq(user.id.to_s)
    end

    it "returns errors with invalid attributes" do
      put "/api/v1/events/#{event.id}/tips/#{tip.id}", params: { 
        tip: { amount: nil } 
      }
      
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response[:error]).to eq("Failed to update tip")
      expect(json_response[:details]).to be_present
    end
  end

  describe "DELETE /api/v1/events/:event_id/tips/:id" do
    it "deletes the tip" do
      tip # create the tip
      expect {
        delete "/api/v1/events/#{event.id}/tips/#{tip.id}"
      }.to change(Tip, :count).by(-1)
      
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "Integration with existing API structure" do
    it "includes tips in event API responses" do
      tip # create the tip
      get "/api/v1/events/#{event.id}"
      
      expect(response).to have_http_status(:ok)
      
      # Check that tips are included in the JSON:API response
      expect(json_response[:included]).to be_present
      tip_resource = json_response[:included].find { |resource| resource[:type] == 'tip' }
      expect(tip_resource).to be_present
      expect(tip_resource[:attributes][:amount]).to eq('25.5')
      
      # Check that the event has a relationship to tips
      event_data = json_response[:data]
      expect(event_data[:relationships][:tips][:data]).to be_present
      expect(event_data[:relationships][:tips][:data].first[:id]).to eq(tip.id.to_s)
    end
  end
end
