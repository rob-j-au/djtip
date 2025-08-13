require 'rails_helper'

RSpec.describe TipsHelper, type: :helper do
  describe "helper module" do
    it "is included in the view context" do
      expect(helper.class.included_modules).to include(TipsHelper)
    end
    
    it "provides access to Rails helpers" do
      expect(helper).to respond_to(:link_to)
      expect(helper).to respond_to(:number_to_currency)
    end
  end
  
  describe "currency formatting" do
    it "can format currency amounts using Rails helpers" do
      expect(helper.number_to_currency(25.50)).to eq("$25.50")
    end
    
    it "can format different currencies" do
      expect(helper.number_to_currency(20.00, unit: "€")).to eq("€20.00")
    end
  end
end
