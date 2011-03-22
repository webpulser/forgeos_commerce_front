ActionController::Routing::Routes.draw do |map|
  map.resource :user, :member => { :activate => :get, :new_password => :get, :forgotten_password => :get, :reset_password => :post } do |user|
    user.resources :orders
    user.resources :addresses
    map.resources :address_deliveries, :controller => :addresses, :as => :addresses
    map.resources :address_invoices, :controller => :addresses, :as => :addresses
  end
end
