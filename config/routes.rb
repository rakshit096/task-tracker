Rails.application.routes.draw do

  root "sessions#new"
  
  resource :session
  resources :passwords, param: :token

end
