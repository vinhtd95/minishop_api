Rails.application.routes.draw do
  namespace :api do 
    namespace :v1 do 
      post '/login', to: 'sessions#create'
      post '/logout', to: 'sessions#destroy'
      get '/me', to: 'sessions#show'
    end
  end
end
