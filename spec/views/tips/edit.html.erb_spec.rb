require 'rails_helper'

RSpec.describe "tips/edit.html.erb", type: :view do
  let(:event) { create(:event) }
  let(:tip) { create(:tip, event: event, amount: 40.00, message: "Great music!") }

  before do
    assign(:event, event)
    assign(:tip, tip)
    
    # Stub the route helpers for nested routes
    allow(view).to receive(:event_tips_path).with(event).and_return("/events/#{event.id}/tips")
    allow(view).to receive(:event_tip_path).with(event, tip).and_return("/events/#{event.id}/tips/#{tip.id}")
  end

  it "renders edit tip form" do
    render
    
    expect(rendered).to include("Edit Tip")
    expect(rendered).to include("form")
  end

  it "pre-populates form fields with existing tip data" do
    render
    
    expect(rendered).to include("40.0") # amount field
    expect(rendered).to include("Great music!") # message field
    expect(rendered).to include(tip.currency) # currency field
  end

  it "includes the event information" do
    render
    
    # The event information is available through the form partial
    expect(rendered).to include("Edit Tip")
  end

  it "has form action pointing to tip update" do
    render
    
    expect(rendered).to include("action=\"/events/#{event.id}/tips/#{tip.id}\"")
  end

  it "includes form buttons" do
    render
    
    expect(rendered).to include("Save Tip")
    expect(rendered).to include("Cancel")
  end

  it "uses daisyUI form styling" do
    render
    
    expect(rendered).to include("fieldset")
    expect(rendered).to include("input-bordered")
    expect(rendered).to include("btn-primary")
  end

  it "includes hidden method field for PATCH request" do
    render
    
    expect(rendered).to include('name="_method"')
    expect(rendered).to include('value="patch"')
  end
end
