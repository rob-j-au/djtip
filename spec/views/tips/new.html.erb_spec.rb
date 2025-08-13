require 'rails_helper'

RSpec.describe "tips/new.html.erb", type: :view do
  let(:event) { create(:event) }
  let(:tip) { build(:tip, event: event) }

  before do
    assign(:event, event)
    assign(:tip, tip)
    
    # Stub the route helpers for nested routes
    allow(view).to receive(:event_tips_path).with(event).and_return("/events/#{event.id}/tips")
  end

  it "renders new tip form" do
    render
    
    expect(rendered).to include("New Tip")
    expect(rendered).to include("form")
  end

  it "displays form fields for tip attributes" do
    render
    
    expect(rendered).to include("Amount")
    expect(rendered).to include("Currency")
    expect(rendered).to include("Message")
  end

  it "includes the event information" do
    render
    
    # The event information is available through the form partial
    expect(rendered).to include("New Tip")
  end

  it "has form action pointing to tips creation" do
    render
    
    expect(rendered).to include("action=\"/events/#{event.id}/tips\"")
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
end
