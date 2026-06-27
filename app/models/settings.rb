# frozen_string_literal: true

class Settings < Settingslogic
  source "#{Rails.root}/config/application.yml"
  namespace Rails.env
  suppress_errors true # Returns nil for missing keys instead of raising
end
