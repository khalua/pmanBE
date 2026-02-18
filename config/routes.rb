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
    resource :preferences, only: [ :show, :update ], controller: "preferences"
    namespace :tenant do
      get "dashboard", to: "dashboard#show"
      resource :profile, only: [ :edit, :update ]
      resources :maintenance_requests, only: [ :show ] do
        member do
          post :create_note
        end
      end
    end
    namespace :manager do
      get "dashboard", to: "dashboard#show"
      resources :tenants, only: [ :index, :show ] do
        member do
          post :move_out
          post :activate
        end
      end
      resources :vendors, only: [ :index, :create, :destroy ]
      resources :properties, only: [] do
        resources :invitations, only: [ :index, :create ] do
          member do
            post :revoke
          end
        end
      end
      resources :maintenance_requests, only: [ :show ] do
        resources :quote_requests, only: [ :create ]
        member do
          post :create_note
          post :close
          post :mark_in_progress
          post :mark_complete
        end
      end
      resources :quotes, only: [] do
        member do
          post :approve
          get :select_message
          post :send_approval_message
          post :reject
        end
      end
    end
    namespace :admin do
      get "dashboard", to: "dashboard#show"
      resources :users, only: [ :index, :destroy ]
      resources :properties, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
        resources :units, only: [ :new, :create, :edit, :update, :destroy ]
      end
      resources :maintenance_requests, only: [ :index, :show, :destroy ]
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
        post :close
        post :mark_complete
      end
      resources :notes, only: [ :index, :create ], controller: "maintenance_requests/notes"
    end

    resources :vendors, only: [ :index, :show ]

    resources :quotes, only: [ :create ] do
      member do
        post :approve
        post :reject
      end
    end

    post "device_tokens", to: "device_tokens#create"
    delete "device_tokens", to: "device_tokens#destroy"

    post "chat", to: "chat#chat"
    post "summarize", to: "chat#summarize"

    post "reset", to: "reset#create"

    post "phone/verify/send", to: "phone_verifications#send_code"
    post "phone/verify/confirm", to: "phone_verifications#confirm"

    namespace :manager do
      resources :vendors, only: [ :index, :show, :create, :destroy ]
      resources :maintenance_requests, only: [] do
        resources :quote_requests, only: [ :index, :create ]
      end
      resources :properties, only: [] do
        resources :invitations, only: [ :index ]
        resources :units, only: [] do
          resources :invitations, only: [ :create ]
        end
      end
      resources :invitations, only: [ :destroy ]
      resources :tenants, only: [ :show, :update ] do
        member do
          post :move_out
          post :activate
        end
      end
    end

    namespace :admin do
      get "dashboard", to: "dashboard#show"
      resources :users, only: [ :index, :destroy ]
      resources :maintenance_requests, only: [ :index, :show, :destroy ]
      resources :properties, only: [ :index, :show, :create, :update, :destroy ] do
        resources :units, only: [ :create, :update, :destroy ]
      end
    end
  end

  get "quote", to: "vendor_portal#show"
  get "health", to: "health#show"
end
