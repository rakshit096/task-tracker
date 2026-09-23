Rails.application.routes.draw do
  root "projects#index"

  resource :session
  resources :passwords, param: :token
  resource :registration, only: %i[ new create ]

  resources :projects do                       # tasks are nested under projects and it generates all restful actions except the two mentioned
    resources :tasks, except: [] do
      member do
        patch :update_status
      end
    end
  end

  get "my_tasks", to: "tasks#assigned_to_me"
end
