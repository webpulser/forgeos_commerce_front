Forgeos::CommerceFront::Engine.routes.draw do
  resource :user do
    member do
      get :activate
      get :new_password
      get :forgotten_password
      put :update_password
      post :reset_password
    end

    resources :orders
    resources :addresses

    resources :address_deliveries, :controller => :addresses, :as => :addresses
    resources :address_invoices, :controller => :addresses, :as => :addresses
  end
end
