Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

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
  end
end
