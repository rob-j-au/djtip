require 'rails_helper'

RSpec.describe "tips/index.html.erb", type: :view do
  let(:event) { create(:event) }
  let!(:tip1) { create(:tip, event: event, amount: 25.50, message: "Great show!") }
  let!(:tip2) { create(:tip, event: event, amount: 50.00, message: "Amazing performance!") }

  before do
    assign(:event, event)
    assign(:tips, [tip1, tip2])
    
    # Stub the route helpers for nested routes
    allow(view).to receive(:event_tip_path).and_return("/events/#{event.id}/tips/1")
    allow(view).to receive(:edit_event_tip_path).and_return("/events/#{event.id}/tips/1/edit")
    allow(view).to receive(:new_event_tip_path).with(event).and_return("/events/#{event.id}/tips/new")
  end

  it "renders a list of tips" do
    render
    
    expect(rendered).to match(/Tips for/)
    expect(rendered).to include(event.title)
  end

  it "displays tip amounts" do
    render
    
    expect(rendered).to include("25.5")
    expect(rendered).to include("50.0")
  end

  it "displays tip messages" do
    render
    
    expect(rendered).to include("Great show!")
    expect(rendered).to include("Amazing performance!")
  end

  it "displays user information for each tip" do
    render
    
    expect(rendered).to include(tip1.user.name)
    expect(rendered).to include(tip2.user.name)
  end

  it "includes action links for each tip" do
    render
    
    expect(rendered).to include("View")
    expect(rendered).to include("Edit")
    expect(rendered).to include("Delete")
  end

  context "when there are no tips" do
    before do
      assign(:tips, [])
    end

    it "displays an empty state message" do
      render
      
      expect(rendered).to include("No tips yet")
    end
  end
end
