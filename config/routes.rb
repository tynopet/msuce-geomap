Rails.application.routes.draw do
  root to: 'gmaps#index'
  resources :gmaps, only: [:index, :create] do
    get :download, on: :collection
  end
end
