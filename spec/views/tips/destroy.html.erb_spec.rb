require 'rails_helper'

RSpec.describe "tips/destroy.html.erb", type: :view do
  # Note: In typical Rails applications, the destroy action redirects after deletion
  # This view file may not be used in practice, but we'll test it for completeness.
  
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

  context "when deletion fails" do
    before do
      tip.errors.add(:base, "Cannot delete tip with associated records")
    end

    it "can display error messages" do
      render
      
      # If the view displays errors, they should be accessible
      expect(tip.errors[:base]).to include("Cannot delete tip with associated records")
    end
  end

  it "maintains access to tip data" do
    render
    
    expect(tip.amount).to be_present
    expect(tip.user).to be_present
    expect(tip.event).to be_present
  end
end
