Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Web routes
  root "pages#landing"
  get "privacy", to: "pages#privacy"
  get "terms", to: "pages#terms"

  get "login", to: "web/sessions#new"
  post "login", to: "web/sessions#create"
  delete "logout", to: "web/sessions#destroy"

  get "register", to: "web/registrations#new"
  post "register", to: "web/registrations#create"

  get "forgot_password", to: "web/password_resets#new"
  post "forgot_password", to: "web/password_resets#create"
  get "reset_password", to: "web/password_resets#edit"
  patch "reset_password", to: "web/password_resets#update"

  namespace :web do
    namespace :tenant do
      get "dashboard", to: "dashboard#show"
    end
    namespace :manager do
      get "dashboard", to: "dashboard#show"
      resources :vendors, only: [ :index, :create, :destroy ]
      resources :maintenance_requests, only: [ :show ] do
        resources :quote_requests, only: [ :create ]
      end
    end
    namespace :admin do
      get "dashboard", to: "dashboard#show"
      resources :users, only: [ :index, :destroy ]
      resources :properties, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
        resources :units, only: [ :new, :create, :edit, :update, :destroy ]
      end
    end
  end

  # OmniAuth
  get "/auth/google_oauth2/callback", to: "web/oauth#google"
  get "/auth/failure", to: "web/oauth#failure"

  # API routes
  namespace :api do
    post "register", to: "auth#register"
    post "login", to: "auth#login"
    get "me", to: "auth#me"

    resources :maintenance_requests, only: [ :index, :show, :create, :update ] do
      member do
        post :assign_vendor
      end
    end

    resources :vendors, only: [ :index, :show ]

    resources :quotes, only: [ :create ] do
      member do
        post :approve
        post :reject
      end
    end

    post "chat", to: "chat#chat"
    post "summarize", to: "chat#summarize"

    post "reset", to: "reset#create"

    namespace :manager do
      resources :vendors, only: [ :index, :show, :create, :destroy ]
      resources :maintenance_requests, only: [] do
        resources :quote_requests, only: [ :index, :create ]
      end
    end

    namespace :admin do
      get "dashboard", to: "dashboard#show"
      resources :users, only: [ :index, :destroy ]
      resources :maintenance_requests, only: [ :index ]
      resources :properties, only: [ :index, :show, :create, :update, :destroy ] do
        resources :units, only: [ :create, :update, :destroy ]
      end
    end
  end

  get "quote", to: "vendor_portal#show"
  get "health", to: "health#show"
end
