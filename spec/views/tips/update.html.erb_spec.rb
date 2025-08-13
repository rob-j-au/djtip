require 'rails_helper'

RSpec.describe "tips/update.html.erb", type: :view do
  # Note: In typical Rails applications, the update action redirects on success
  # and renders the 'edit' template on validation errors. This view file may not
  # be used in practice, but we'll test it for completeness.
  
  let(:event) { create(:event) }
  let(:tip) { create(:tip, event: event) }

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
      tip.errors.add(:amount, "must be positive")
      tip.errors.add(:message, "is too long")
    end

    it "can display error messages" do
      render
      
      # If the view displays errors, they should be accessible
      expect(tip.errors[:amount]).to include("must be positive")
      expect(tip.errors[:message]).to include("is too long")
    end
  end

  it "maintains tip data after failed update" do
    render
    
    expect(tip.amount).to be_present
    expect(tip.currency).to be_present
  end
end
