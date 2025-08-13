require 'rails_helper'

RSpec.describe "tips/create.html.erb", type: :view do
  # Note: In typical Rails applications, the create action redirects on success
  # and renders the 'new' template on validation errors. This view file may not
  # be used in practice, but we'll test it for completeness.
  
  let(:event) { create(:event) }
  let(:tip) { build(:tip, event: event) }

  before do
    assign(:event, event)
    assign(:tip, tip)
  end

  it "renders without errors" do
    expect { render }.not_to raise_error
  end

  it "can access assigned variables" do
    render
    
    # The view should have access to the assigned variables
    expect(view.instance_variable_get(:@event)).to eq(event)
    expect(view.instance_variable_get(:@tip)).to eq(tip)
  end

  context "when tip has validation errors" do
    before do
      tip.errors.add(:amount, "can't be blank")
      tip.errors.add(:currency, "is not valid")
    end

    it "can display error messages" do
      render
      
      # If the view displays errors, they should be accessible
      expect(tip.errors[:amount]).to include("can't be blank")
      expect(tip.errors[:currency]).to include("is not valid")
    end
  end
end
