ActionController::Routing::Routes.draw do |map|
  map.resources :users
  map.resource :user, :member => { :activate => :get } do |user|
    user.resources :orders
    user.resources :addresses
    map.resources :address_deliveries, :controller => :addresses, :as => :addresses
    map.resources :address_invoices, :controller => :addresses, :as => :addresses
  end
end
