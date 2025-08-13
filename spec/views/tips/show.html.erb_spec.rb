require 'rails_helper'

RSpec.describe "tips/show.html.erb", type: :view do
  let(:event) { create(:event) }
  let(:tip) { create(:tip, event: event, amount: 75.00, message: "Outstanding performance!") }

  before do
    assign(:tip, tip)
    assign(:event, event)
    
    # Stub the route helpers for nested routes
    allow(view).to receive(:edit_event_tip_path).with(event, tip).and_return("/events/#{event.id}/tips/#{tip.id}/edit")
    allow(view).to receive(:event_tips_path).with(event).and_return("/events/#{event.id}/tips")
  end

  it "renders tip details" do
    render
    
    expect(rendered).to include("Tip Details")
    expect(rendered).to include("USD 75.0")
    expect(rendered).to include("Outstanding performance!")
  end

  it "displays the associated user information" do
    render
    
    expect(rendered).to include(tip.user.name)
    expect(rendered).to include(tip.user.email)
  end

  it "displays the associated event information" do
    render
    
    expect(rendered).to include(tip.event.title)
    expect(rendered).to include(tip.event.location)
  end

  it "includes action links" do
    render
    
    expect(rendered).to include("Edit")
    expect(rendered).to include("Back to Tips")
  end

  it "displays tip metadata" do
    render
    
    expect(rendered).to include("Created")
    expect(rendered).to include("USD")
  end

  context "when tip has no message" do
    let(:tip) { create(:tip, :without_message, event: event) }

    it "handles missing message gracefully" do
      render
      
      expect(rendered).not_to include("Outstanding performance!")
      expect(rendered).to include("USD 25.5") # default factory amount
    end
  end
end
