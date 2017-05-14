Rails.application.routes.draw do
  root 'users#index'

  resources :rewards
  resources :groups
  resources :transactions
  resources :users

  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      post '/slack', to: 'slack#index'
      post '/slack_redeem', to: 'slack#redeem'
      get  '/slack_photo', to: 'slack#photo'
    end
  end
end
