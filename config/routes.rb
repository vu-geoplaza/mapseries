Rails.application.routes.draw do
  devise_for :users
  resources :base_series do
    resources :base_sheets
    resources :base_sets
    resources :sheets
    resources :copies
  end

  resources :base_sheets do
    resources :sheets
    resources :copies
  end

  resources :base_sets do
    resources :sheets
  end

  resources :sheets do
    resources :copies
  end

  resources :copies do
    resources :electronic_versions
  end

  resources :libraries do
    resources :copies
  end

  root to: 'sheets#search'

  get 'search', to: 'sheets#search'
  post 'result_sheet', to: 'sheets#results'

  get 'query', to: 'sheets#query'
end

