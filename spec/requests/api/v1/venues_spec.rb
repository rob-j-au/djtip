# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Venues', type: :request do
  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  describe 'GET /api/v1/venues' do
    let!(:venues) { create_list(:venue, 3) }
    let!(:events) { create_list(:event, 2, venue: venues.first) }

    it 'returns all venues with associated events' do
      get '/api/v1/venues'

      expect(response).to have_http_status(:ok)

      expect(json_response[:data]).to be_an(Array)
      expect(json_response[:data].length).to eq(3)

      venue_with_events = json_response[:data].find do |venue|
        venue[:relationships][:events][:data].length == 2
      end

      expect(venue_with_events).to be_present
      expect(venue_with_events[:type]).to eq('venue')

      expect(json_response[:included]).to be_present
      event_resources = json_response[:included].select { |resource| resource[:type] == 'event' }
      expect(event_resources.length).to eq(2)
    end
  end

  describe 'GET /api/v1/venues/:id' do
    let!(:venue) { create(:venue) }
    let!(:events) { create_list(:event, 2, venue: venue) }

    it 'returns the venue with associated events' do
      get "/api/v1/venues/#{venue.id}"

      expect(response).to have_http_status(:ok)

      venue_data = json_response[:data]
      expect(venue_data[:type]).to eq('venue')
      expect(venue_data[:id]).to eq(venue.id.to_s)
      expect(venue_data[:attributes][:name]).to eq(venue.name)
      expect(venue_data[:attributes][:venue_type]).to eq(venue.venue_type)

      expect(venue_data[:relationships][:events][:data].length).to eq(2)

      expect(json_response[:included]).to be_present
      event_resources = json_response[:included].select { |resource| resource[:type] == 'event' }
      expect(event_resources.length).to eq(2)
    end

    it 'returns 404 for non-existent venue' do
      get '/api/v1/venues/nonexistent'

      expect(response).to have_http_status(:not_found)
      expect(json_response[:error]).to eq('Resource not found')
    end
  end

  describe 'POST /api/v1/venues' do
    let(:valid_attributes) do
      {
        name: 'Test Venue',
        venue_type: 'club'
      }
    end

    let(:invalid_attributes) do
      {
        name: '',
        venue_type: 'invalid_type'
      }
    end

    it 'creates a new venue with valid attributes' do
      expect do
        post '/api/v1/venues', params: { venue: valid_attributes }
      end.to change(Venue, :count).by(1)

      expect(response).to have_http_status(:created)

      venue_data = json_response[:data]
      expect(venue_data[:type]).to eq('venue')
      expect(venue_data[:attributes][:name]).to eq('Test Venue')
      expect(venue_data[:attributes][:venue_type]).to eq('club')
    end

    it 'returns errors with invalid attributes' do
      post '/api/v1/venues', params: { venue: invalid_attributes }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response[:error]).to eq('Failed to create venue')
      expect(json_response[:details]).to be_present
    end
  end

  describe 'PUT /api/v1/venues/:id' do
    let!(:venue) { create(:venue) }
    let(:valid_attributes) { { name: 'Updated Venue' } }
    let(:invalid_attributes) { { name: '' } }

    it 'updates the venue with valid attributes' do
      put "/api/v1/venues/#{venue.id}", params: { venue: valid_attributes }

      expect(response).to have_http_status(:ok)

      venue_data = json_response[:data]
      expect(venue_data[:type]).to eq('venue')
      expect(venue_data[:attributes][:name]).to eq('Updated Venue')
    end

    it 'returns errors with invalid attributes' do
      put "/api/v1/venues/#{venue.id}", params: { venue: invalid_attributes }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response[:error]).to eq('Failed to update venue')
    end
  end

  describe 'DELETE /api/v1/venues/:id' do
    let!(:venue) { create(:venue) }

    it 'deletes the venue' do
      expect do
        delete "/api/v1/venues/#{venue.id}"
      end.to change(Venue, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
