require 'rails_helper'

RSpec.describe "Admin::Dashboard", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  describe "GET /admin" do
    context "when user is admin" do
      before { sign_in admin_user }
      
      it "returns success" do
        get "/admin"
        expect(response).to have_http_status(:success)
      end

      it "displays dashboard content" do
        get "/admin"
        expect(response.body).to include("Admin Panel")
      end

      it "shows statistics" do
        create_list(:event, 3)
        create_list(:user, 5)
        create_list(:performer, 2)
        
        get "/admin"
        expect(response.body).to include("3") # events count
        expect(response.body).to include("6") # users count (5 + admin)
        expect(response.body).to include("2") # performers count
      end
    end

    context "when user is not admin" do
      before { sign_in regular_user }

      it "redirects to root path" do
        get "/admin"
        expect(response).to redirect_to("/")
      end

      it "shows access denied message" do
        get "/admin"
        follow_redirect!
        expect(response.body).to include("Access denied")
      end
    end

    context "when user is not signed in" do

      it "redirects to sign in" do
        get "/admin"
        expect(response).to redirect_to("/users/sign_in")
      end
    end
  end
end
