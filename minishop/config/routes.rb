Rails.application.routes.draw do
  namespace :api do 
    namespace :v1 do 
      #authenticate routes
      post '/login', to: 'sessions#create'
      post '/logout', to: 'sessions#destroy'
      get '/me', to: 'sessions#show'

      #category routes
      get    '/categories',     to: 'categories#index'   
      get    '/categories/:id', to: 'categories#show'    
      post   '/categories',     to: 'categories#create' 
      patch  '/categories/:id', to: 'categories#update'  
      delete '/categories/:id', to: 'categories#destroy' 

      #product routes 
      get '/products', to: 'products#index'

      #cart routes 
      resource :cart, only: [:show], controller: 'cart' do #do nguoi dung chi co duy nhat 1 gio hang -> resource not resources 
        resources :items, only: [:create, :update, :destroy], controller: 'cart_items'
      end
    end
  end
end
