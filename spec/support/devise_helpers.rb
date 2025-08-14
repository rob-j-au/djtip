RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::ControllerHelpers, type: :controller
  
  # Ensure Devise mappings are loaded in test environment
  config.before(:suite) do
    Rails.application.reload_routes!
    Devise.mappings[:user] ||= Devise.add_mapping(:user, {
      class_name: 'User',
      path: 'users',
      path_names: { sign_in: 'sign_in', sign_out: 'sign_out' }
    })
  end
end

# Custom authentication helper for request specs
module AuthenticationHelpers
  def sign_in_admin
    admin_user = create(:user, :admin)
    sign_in admin_user, scope: :user
    admin_user
  end
  
  def sign_in_regular_user
    regular_user = create(:user)
    sign_in regular_user, scope: :user
    regular_user
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end
