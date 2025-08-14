require 'rails_helper'

RSpec.describe "Admin::Events", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:event) { create(:event) }

  before do
    sign_in admin_user
  end

  describe "GET /admin/events" do
    it "returns success" do
      get "/admin/events"
      expect(response).to have_http_status(:success)
    end

    it "displays events list" do
      get "/admin/events"
      expect(response.body).to include("Events")
    end

    it "filters by status" do
      get "/admin/events", params: { filter: 'active' }
      expect(response).to have_http_status(:success)
    end

    it "searches events" do
      get "/admin/events", params: { search: event.title }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/events/:id" do
    it "shows event details" do
      get "/admin/events/#{event.id}"
      expect(response).to have_http_status(:success)
      expect(response.body).to include(event.title)
    end
  end

  describe "GET /admin/events/new" do
    it "shows new event form" do
      get "/admin/events/new"
      expect(response).to have_http_status(:success)
      expect(response.body).to include("New Event")
    end
  end

  describe "POST /admin/events" do
    let(:valid_attributes) do
      {
        title: "Test Event",
        description: "Test Description",
        date: Date.current,
        location: "Test Location"
      }
    end

    let(:invalid_attributes) do
      {
        title: "",
        date: nil
      }
    end

    context "with valid parameters" do
      it "creates a new event" do
        expect {
          post "/admin/events", params: { event: valid_attributes }
        }.to change(Event, :count).by(1)
      end

      it "redirects to the created event" do
        post "/admin/events", params: { event: valid_attributes }
        expect(response).to redirect_to("/admin/events/#{Event.last.id}")
      end
    end

    context "with invalid parameters" do
      it "does not create a new event" do
        expect {
          post "/admin/events", params: { event: invalid_attributes }
        }.to change(Event, :count).by(0)
      end

      it "renders the new template" do
        post "/admin/events", params: { event: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /admin/events/:id/edit" do
    it "shows edit event form" do
      get "/admin/events/#{event.id}/edit"
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Edit Event")
    end
  end

  describe "PATCH /admin/events/:id" do
    let(:valid_attributes) do
      { title: "Updated Title" }
    end

    context "with valid parameters" do
      it "updates the event" do
        patch "/admin/events/#{event.id}", params: { event: valid_attributes }
        event.reload
        expect(event.title).to eq("Updated Title")
      end

      it "redirects to the event" do
        patch "/admin/events/#{event.id}", params: { event: valid_attributes }
        expect(response).to redirect_to("/admin/events/#{event.id}")
      end
    end
  end

  describe "DELETE /admin/events/:id" do
    it "destroys the event" do
      event_to_delete = create(:event)
      expect {
        delete "/admin/events/#{event_to_delete.id}"
      }.to change(Event, :count).by(-1)
    end

    it "redirects to events list" do
      delete "/admin/events/#{event.id}"
      expect(response).to redirect_to("/admin/events")
    end
  end

  describe "PATCH /admin/events/:id/toggle_status" do
    it "toggles event status" do
      patch "/admin/events/#{event.id}/toggle_status"
      expect(response).to redirect_to("/admin/events/#{event.id}")
    end
  end
end
