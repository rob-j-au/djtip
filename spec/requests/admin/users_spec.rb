require 'rails_helper'

RSpec.describe "Admin::Users", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    sign_in admin_user
  end

  describe "GET /admin/users" do
    it "returns success" do
      get "/admin/users"
      expect(response).to have_http_status(:success)
    end

    it "displays users list" do
      get "/admin/users"
      expect(response.body).to include("Users")
      expect(response.body).to include(admin_user.name)
    end

    it "filters by admin status" do
      get "/admin/users", params: { filter: 'admins' }
      expect(response).to have_http_status(:success)
    end

    it "searches users" do
      get "/admin/users", params: { search: admin_user.name }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/users/:id" do
    it "shows user details" do
      get "/admin/users/#{other_user.id}"
      expect(response).to have_http_status(:success)
      expect(response.body).to include(other_user.name)
    end
  end

  describe "GET /admin/users/new" do
    it "shows new user form" do
      get "/admin/users/new"
      expect(response).to have_http_status(:success)
      expect(response.body).to include("New User")
    end
  end

  describe "POST /admin/users" do
    let(:valid_attributes) do
      {
        name: "Test User",
        email: "test@example.com",
        phone: "123-456-7890"
      }
    end

    let(:invalid_attributes) do
      {
        name: "",
        email: "invalid-email"
      }
    end

    context "with valid parameters" do
      it "creates a new user" do
        expect {
          post "/admin/users", params: { user: valid_attributes }
        }.to change(User, :count).by(1)
      end

      it "redirects to the created user" do
        post "/admin/users", params: { user: valid_attributes }
        expect(response).to redirect_to("/admin/users/#{User.last.id}")
      end
    end

    context "with invalid parameters" do
      it "does not create a new user" do
        expect {
          post "/admin/users", params: { user: invalid_attributes }
        }.to change(User, :count).by(0)
      end

      it "renders the new template" do
        post "/admin/users", params: { user: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /admin/users/:id/edit" do
    it "shows edit user form" do
      get "/admin/users/#{other_user.id}/edit"
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Edit User")
    end
  end

  describe "PATCH /admin/users/:id" do
    let(:valid_attributes) do
      { name: "Updated Name" }
    end

    let(:invalid_attributes) do
      { email: "invalid-email" }
    end

    context "with valid parameters" do
      it "updates the user" do
        patch "/admin/users/#{other_user.id}", params: { user: valid_attributes }
        other_user.reload
        expect(other_user.name).to eq("Updated Name")
      end

      it "redirects to the user" do
        patch "/admin/users/#{other_user.id}", params: { user: valid_attributes }
        expect(response).to redirect_to("/admin/users/#{other_user.id}")
      end
    end

    context "with invalid parameters" do
      it "renders the edit template" do
        patch "/admin/users/#{other_user.id}", params: { user: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /admin/users/:id" do
    it "destroys the user" do
      user_to_delete = create(:user)
      expect {
        delete "/admin/users/#{user_to_delete.id}"
      }.to change(User, :count).by(-1)
    end

    it "redirects to users list" do
      delete "/admin/users/#{other_user.id}"
      expect(response).to redirect_to("/admin/users")
    end

    it "prevents admin from deleting themselves" do
      delete "/admin/users/#{admin_user.id}"
      expect(response).to redirect_to("/admin/users")
      expect(flash[:alert]).to include("cannot delete yourself")
    end
  end

  describe "PATCH /admin/users/:id/toggle_admin" do
    it "toggles admin status" do
      expect {
        patch "/admin/users/#{other_user.id}/toggle_admin"
        other_user.reload
      }.to change(other_user, :admin?).from(false).to(true)
    end

    it "prevents admin from changing own status" do
      patch "/admin/users/#{admin_user.id}/toggle_admin"
      expect(response).to redirect_to("/admin/users/#{admin_user.id}")
      expect(flash[:alert]).to include("cannot change your own admin status")
    end
  end

  context "when user is not admin" do
    before do
      sign_out admin_user
      sign_in regular_user
    end

    it "redirects to root path" do
      get "/admin/users"
      expect(response).to redirect_to("/")
    end
  end
end
