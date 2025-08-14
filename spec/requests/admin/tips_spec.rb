require 'rails_helper'

RSpec.describe "Admin::Tips", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:tip) { create(:tip) }
  let(:event) { create(:event) }
  let(:user) { create(:user) }

  before do
    sign_in admin_user
  end

  describe "GET /admin/tips" do
    it "returns success" do
      get "/admin/tips"
      expect(response).to have_http_status(:success)
    end

    it "displays tips list" do
      get "/admin/tips"
      expect(response.body).to include("Tips")
    end

    it "filters by event" do
      get "/admin/tips", params: { event_id: event.id }
      expect(response).to have_http_status(:success)
    end

    it "filters by user" do
      get "/admin/tips", params: { user_id: user.id }
      expect(response).to have_http_status(:success)
    end

    it "filters by amount range" do
      get "/admin/tips", params: { min_amount: 10, max_amount: 100 }
      expect(response).to have_http_status(:success)
    end

    it "searches tips" do
      get "/admin/tips", params: { search: "test" }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/tips/:id" do
    it "shows tip details" do
      get "/admin/tips/#{tip.id}"
      expect(response).to have_http_status(:success)
      expect(response.body).to include("$#{tip.amount}")
    end
  end

  describe "GET /admin/tips/:id/edit" do
    it "shows edit tip form" do
      get "/admin/tips/#{tip.id}/edit"
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Edit Tip")
      expect(response.body).to include("value=\"#{tip.amount}\"")
    end
  end

  describe "PATCH /admin/tips/:id" do
    let(:valid_attributes) { { amount: 25.50, message: "Updated tip message" } }
    let(:invalid_attributes) { { amount: -10 } }

    context "with valid parameters" do
      it "updates the tip" do
        patch "/admin/tips/#{tip.id}", params: { tip: valid_attributes }
        tip.reload
        expect(tip.amount).to eq(25.50)
        expect(tip.message).to eq("Updated tip message")
      end

      it "redirects to the tip" do
        patch "/admin/tips/#{tip.id}", params: { tip: valid_attributes }
        expect(response).to redirect_to("/admin/tips/#{tip.id}")
      end
    end

    context "with invalid parameters" do
      it "renders the edit template" do
        patch "/admin/tips/#{tip.id}", params: { tip: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Edit Tip")
      end
    end
  end

  describe "DELETE /admin/tips/:id" do
    it "destroys the tip" do
      tip_to_delete = create(:tip)
      expect {
        delete "/admin/tips/#{tip_to_delete.id}"
      }.to change(Tip, :count).by(-1)
    end

    it "redirects to tips list" do
      delete "/admin/tips/#{tip.id}"
      expect(response).to redirect_to("/admin/tips")
    end
  end

  context "when user is not admin" do
    let(:regular_user) { create(:user) }

    before do
      sign_out admin_user
      sign_in regular_user
    end

    it "redirects to root path" do
      get "/admin/tips"
      expect(response).to redirect_to("/")
    end
  end
end
