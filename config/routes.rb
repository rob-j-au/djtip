require 'sidekiq/web'

Rails.application.routes.draw do
  # Devise routes for authentication (skip registrations to avoid conflict with custom UsersController)
  devise_for :users, skip: [:registrations]
  
  # mount RailsAdmin::Engine => '/admin', as: 'rails_admin' - REMOVED
  
  # Admin Interface (Rails 8 + daisyUI) - moved from /new_admin to /admin
  namespace :admin do
    root 'dashboard#index'
    resources :events do
      member do
        patch :toggle_status
      end
    end
    resources :users do
      member do
        patch :toggle_admin
      end
    end
    resources :performers
    resources :tips, only: [:index, :show, :edit, :update, :destroy]
  end
  

  
  # Sidekiq Web UI
  mount Sidekiq::Web => '/sidekiq'
  
  resources :performers
  resources :users
  resources :events do
    resources :users, shallow: true, only: [:new, :create]
    resources :performers, shallow: true, only: [:new, :create]
    resources :tips
  end
  
  # Chrome DevTools / RailsPanel support
  get "/.well-known/appspecific/com.chrome.devtools.json", to: proc { [200, {}, ['']] }
  
  # API routes
  namespace :api do
    namespace :v1 do
      resources :events, defaults: { format: :json } do
        resources :performers, shallow: true
        resources :tips
      end
      resources :users, defaults: { format: :json }
      resources :performers, defaults: { format: :json }
    end
  end
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  
  # Root route
  root 'events#index'

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by uptime monitors and load balancers.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Root route already defined above as root 'events#index'
end
