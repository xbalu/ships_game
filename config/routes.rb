Rails.application.routes.draw do
  devise_for :users
  root 'home#index'
  resources :games do
    member do
      get 'join', to: 'games#join', as: 'join'
      get 'get_game_data', to: 'games#send_data_to_js'
      post 'send_game_data', to: 'games#get_data_from_js'
    end
  end

  get 'user_games', to: 'games#user_games', as: 'user_games'
  get 'join_first_pending', to: 'games#join_first_pending', as: 'join_first_pending'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
