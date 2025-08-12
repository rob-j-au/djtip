Rails.application.routes.draw do
  resources :performers
  resources :users
  resources :events do
    resources :users, shallow: true, only: [:new, :create]
    resources :performers, shallow: true, only: [:new, :create]
    resources :tips
  end
  
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

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by uptime monitors and load balancers.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  root "home#index"
end
