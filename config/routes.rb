Rails.application.routes.draw do

  root "projects#new"

  resource :session
  resources :passwords, param: :token
  resource :registration, only: %i[ new create ]
  resources :projects


end
