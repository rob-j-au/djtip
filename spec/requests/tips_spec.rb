require 'rails_helper'

RSpec.describe "/events/:event_id/tips", type: :request do
  let(:event) { create(:event) }
  let(:user) { create(:user) }
  let(:tip) { create(:tip, event: event, user: user) }
  
  let(:valid_attributes) {
    {
      amount: 10.50,
      currency: 'USD',
      message: 'Great performance!',
      user_id: user.id
    }
  }

  let(:invalid_attributes) {
    {
      amount: nil,
      currency: '',
      user_id: nil
    }
  }

  describe "GET /events/:event_id/tips" do
    it "renders a successful response" do
      tip # create the tip
      get event_tips_url(event)
      expect(response).to be_successful
    end
  end

  describe "GET /events/:event_id/tips/:id" do
    it "renders a successful response" do
      get "/events/#{event.id}/tips/#{tip.id}"
      expect(response).to be_successful
    end
  end

  describe "GET /events/:event_id/tips/new" do
    it "renders a successful response" do
      get "/events/#{event.id}/tips/new"
      expect(response).to be_successful
    end
  end

  describe "GET /events/:event_id/tips/:id/edit" do
    it "renders a successful response" do
      get "/events/#{event.id}/tips/#{tip.id}/edit"
      expect(response).to be_successful
    end
  end

  describe "POST /events/:event_id/tips" do
    context "with valid parameters" do
      it "creates a new Tip" do
        expect {
          post "/events/#{event.id}/tips", params: { tip: valid_attributes }
        }.to change(Tip, :count).by(1)
      end

      it "redirects to the created tip" do
        post "/events/#{event.id}/tips", params: { tip: valid_attributes }
        expect(response).to redirect_to("/events/#{event.id}/tips/#{Tip.last.id}")
      end
      
      it "associates the tip with the event" do
        post "/events/#{event.id}/tips", params: { tip: valid_attributes }
        expect(Tip.last.event).to eq(event)
      end
    end

    context "with invalid parameters" do
      it "does not create a new Tip" do
        expect {
          post "/events/#{event.id}/tips", params: { tip: invalid_attributes }
        }.to change(Tip, :count).by(0)
      end

      it "renders a successful response (i.e. to display the 'new' template)" do
        post "/events/#{event.id}/tips", params: { tip: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH /events/:event_id/tips/:id" do
    context "with valid parameters" do
      let(:new_attributes) {
        {
          amount: 50.00,
          message: 'Updated message'
        }
      }

      it "updates the requested tip" do
        patch "/events/#{event.id}/tips/#{tip.id}", params: { tip: new_attributes }
        tip.reload
        expect(tip.amount).to eq(50.00)
        expect(tip.message).to eq('Updated message')
      end

      it "redirects to the tip" do
        patch "/events/#{event.id}/tips/#{tip.id}", params: { tip: new_attributes }
        tip.reload
        expect(response).to redirect_to("/events/#{event.id}/tips/#{tip.id}")
      end
    end

    context "with invalid parameters" do
      it "renders a successful response (i.e. to display the 'edit' template)" do
        patch "/events/#{event.id}/tips/#{tip.id}", params: { tip: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /events/:event_id/tips/:id" do
    it "destroys the requested tip" do
      tip # create the tip
      expect {
        delete "/events/#{event.id}/tips/#{tip.id}"
      }.to change(Tip, :count).by(-1)
    end

    it "redirects to the tips list" do
      delete "/events/#{event.id}/tips/#{tip.id}"
      expect(response).to redirect_to("/events/#{event.id}/tips")
    end
  end

  describe "Error handling" do
    describe "when event is not found" do
      let(:invalid_event_id) { 'invalid' }
      
      it "redirects with error for index" do
        get "/events/#{invalid_event_id}/tips"
        expect(response).to redirect_to(events_path)
      end
      
      it "redirects with error for new" do
        get "/events/#{invalid_event_id}/tips/new"
        expect(response).to redirect_to(events_path)
      end
    end
    
    describe "when tip is not found" do
      let(:invalid_tip_id) { 'invalid' }
      
      it "redirects with error for show" do
        get "/events/#{event.id}/tips/#{invalid_tip_id}"
        expect(response).to redirect_to(event_tips_path(event))
      end
    end
  end
end
