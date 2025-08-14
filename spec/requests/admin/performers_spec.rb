require 'rails_helper'

RSpec.describe "Admin::Performers", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:performer) { create(:performer) }
  let(:event) { create(:event) }

  before do
    sign_in admin_user
  end

  describe "GET /admin/performers" do
    it "returns success" do
      get "/admin/performers"
      expect(response).to have_http_status(:success)
    end

    it "displays performers list" do
      get "/admin/performers"
      expect(response.body).to include("Performers")
    end

    it "filters by event" do
      get "/admin/performers", params: { event_id: event.id }
      expect(response).to have_http_status(:success)
    end

    it "searches performers" do
      get "/admin/performers", params: { search: performer.name }
      expect(response).to have_http_status(:success)
    end

    it "handles genre filtering without errors" do
      # This tests the fix for the Mongoid sorting issue
      create(:performer, genre: "Jazz")
      create(:performer, genre: "Rock")
      get "/admin/performers"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/performers/:id" do
    it "shows performer details" do
      get "/admin/performers/#{performer.id}"
      expect(response).to have_http_status(:success)
      expect(response.body).to include(performer.name)
    end
  end

  describe "GET /admin/performers/new" do
    it "shows new performer form" do
      get "/admin/performers/new"
      expect(response).to have_http_status(:success)
      expect(response.body).to include("New Performer")
    end
  end

  describe "POST /admin/performers" do
    let(:valid_attributes) do
      {
        name: "Test Performer",
        email: "testperformer@example.com",
        password: "password123",
        password_confirmation: "password123",
        genre: "Jazz",
        contact: "test@example.com",
        bio: "Test bio"
      }
    end

    let(:invalid_attributes) do
      {
        name: "",
        email: "",
        genre: ""
      }
    end

    context "with valid parameters" do
      it "creates a new performer" do
        expect {
          post "/admin/performers", params: { performer: valid_attributes }
        }.to change(Performer, :count).by(1)
      end

      it "redirects to the created performer" do
        post "/admin/performers", params: { performer: valid_attributes }
        expect(response).to redirect_to("/admin/performers/#{Performer.last.id}")
      end
    end

    context "with invalid parameters" do
      it "does not create a new performer" do
        expect {
          post "/admin/performers", params: { performer: invalid_attributes }
        }.to change(Performer, :count).by(0)
      end

      it "renders the new template" do
        post "/admin/performers", params: { performer: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /admin/performers/:id/edit" do
    it "shows edit performer form" do
      get "/admin/performers/#{performer.id}/edit"
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Edit Performer")
    end
  end

  describe "PATCH /admin/performers/:id" do
    let(:valid_attributes) do
      { name: "Updated Name" }
    end

    context "with valid parameters" do
      it "updates the performer" do
        patch "/admin/performers/#{performer.id}", params: { performer: valid_attributes }
        performer.reload
        expect(performer.name).to eq("Updated Name")
      end

      it "redirects to the performer" do
        patch "/admin/performers/#{performer.id}", params: { performer: valid_attributes }
        expect(response).to redirect_to("/admin/performers/#{performer.id}")
      end
    end
  end

  describe "DELETE /admin/performers/:id" do
    it "destroys the performer" do
      performer_to_delete = create(:performer)
      expect {
        delete "/admin/performers/#{performer_to_delete.id}"
      }.to change(Performer, :count).by(-1)
    end

    it "redirects to performers list" do
      delete "/admin/performers/#{performer.id}"
      expect(response).to redirect_to("/admin/performers")
    end
  end
end
