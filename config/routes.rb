# frozen_string_literal: true

Rails.application.routes.draw do
  # Hack Club OAuth callback (request phase is POST /auth/hackclub via OmniAuth
  # middleware; see config/initializers/omniauth.rb for login-CSRF notes).
  get "/auth/:provider/callback", to: "sessions#create"
  get "/auth/failure", to: "sessions#failure"
  get "sign_in", to: "sessions#new", as: :new_session
  match "logout", to: "sessions#destroy", as: :session, via: %i[get delete]
  # Redirect root path ("/") to the home route
  root "home#index"

  # Routes with named helpers
  get "about", to: "home#about", as: :about
  get "rsvp", to: "home#rsvp", as: :rsvp
  get "rsvps", to: "home#rsvps_count", as: :rsvps
  get "rsvp/thanks", to: "home#rsvp_thanks", as: :rsvp_thanks
  post "rsvp", to: "home#create_rsvp"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
