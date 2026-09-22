Rails.application.routes.draw do
  resource  :session, only: %i[new create destroy]
  resources :passwords, param: :token, only: %i[new create edit update]

  resources :customers do
    resources :activity_notes, only: [ :create ]
    resources :documents,      only: [ :create ]
  end
  resources :jobs do
    resources :orders, shallow: true do
      resources :activity_notes, only: [ :create ]
      resources :documents,      only: [ :create ]
    end
    resources :activity_notes, only: [ :create ]
    resources :documents,      only: [ :create ]
  end
  resources :leads do
    resources :quotes, shallow: true do
      member do
        patch :accept
      end
    end
    resources :activity_notes, only: [ :create ]
    resources :documents,      only: [ :create ]
  end
  resources :activity_notes, only: [ :edit, :update, :destroy ]
  resources :documents,      only: [ :destroy ]


  root "dashboard#show"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
