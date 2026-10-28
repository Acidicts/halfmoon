# frozen_string_literal: true

Rails.application.routes.draw do
  # Redirect root path ("/") to the home route
  root to: redirect('/index')

  # Routes with named helpers
  get 'index', to: 'home#index', as: :home
  get 'about', to: 'home#about', as: :about
  get 'rsvp', to: 'home#rsvp', as: :rsvp

  # Reveal health status on /up that returns 200 if the app boots with no exceptions
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
