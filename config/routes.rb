Rails.application.routes.draw do

  root "projects#index"

  resource :session
  resources :passwords, param: :token
  resource :registration, only: %i[ new create ]

  resources :projects do                       #tasks are nested under projects and it generates all restful actions except the two mentioned
    resources :tasks, except: [:index, :show] do
      member do
        patch :update_status
      end
    end
  end
end
