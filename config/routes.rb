Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '', to: 'home#index'
  post 'login', to:'home#login'
  get 'dashboard', to: "dashboard#index"
  post 'dashboard', to: 'dashboard#get_data_from_feed'
end
