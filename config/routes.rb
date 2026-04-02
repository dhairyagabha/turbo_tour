# frozen_string_literal: true

TurboTour::Engine.routes.draw do
  scope module: :turbo_tour do
    resources :events, only: [:create]
  end
end
