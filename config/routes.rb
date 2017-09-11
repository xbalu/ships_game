Rails.application.routes.draw do
  devise_for :users
  root 'home#index'
  resources :games do
    member do
      get 'join', to: 'games#join', as: 'join'
      get 'get_data'
      post 'send_data'
    end
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
