require 'rails_helper'

RSpec.describe Venue, type: :model do
  let(:venue) { create(:venue) }
  
  describe 'validations' do
    it 'validates presence of name' do
      venue.name = nil
      expect(venue).not_to be_valid
      expect(venue.errors[:name]).to include("can't be blank")
    end
    
    it 'validates presence of venue_type' do
      venue.venue_type = nil
      expect(venue).not_to be_valid
      expect(venue.errors[:venue_type]).to include("can't be blank")
    end
    
    it 'validates venue_type is one of the allowed values' do
      venue.venue_type = 'invalid_type'
      expect(venue).not_to be_valid
      expect(venue.errors[:venue_type]).to include("is not included in the list")
    end
    
    it 'allows valid venue types' do
      %w[bar club festival gallery].each do |type|
        venue.venue_type = type
        expect(venue).to be_valid
      end
    end
  end
  
  describe 'associations' do
    it 'has many events' do
      event1 = create(:event, venue: venue)
      event2 = create(:event, venue: venue)
      
      expect(venue.events).to include(event1, event2)
      expect(venue.events.count).to eq(2)
    end
  end
  
  describe 'factory' do
    it 'creates a valid venue' do
      expect(venue).to be_valid
      expect(venue.name).to be_present
      expect(venue.venue_type).to be_present
      expect(%w[bar club festival gallery]).to include(venue.venue_type)
    end
  end
end
