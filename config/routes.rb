Rails.application.routes.draw do

  root "sessions#new"

  resource :session
  resources :passwords, param: :token
  resource :registration, only: %i[ new create ]

end
