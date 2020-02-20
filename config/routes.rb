# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  get '/iiif/:identifier/manifest', to: 'iiif#manifest', as: :iiif_manifest
  get '/iiif/2/:identifier/:region/:size/:rotation/:quality.:format', to: 'iiif#show'
  get '/iiif/2/:identifier/info.json', to: 'iiif#info'

  mount Riiif::Engine => 'images', as: :riiif if Hyrax.config.iiif_image_server?
  mount Blacklight::Engine => '/'

  get 'importer_documentation/guide', to: 'metadata_details#show'
  get 'importer_documentation/profile', to: 'metadata_details#profile'
  mount Zizia::Engine => '/'

  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end

  devise_for :users, skip: [:registrations], controllers: { omniauth_callbacks: "omniauth_callbacks" }

  # Disable these routes if you are using Devise's
  # database_authenticatable in your development environment.
  unless AuthConfig.use_database_auth?
    devise_scope :user do
      get 'sign_in', to: 'omniauth#new', as: :new_user_session
      post 'sign_in', to: 'omniauth_callbacks#shibboleth', as: :new_session
      get 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
    end
  end

  mount Hydra::RoleManagement::Engine => '/'
  mount Qa::Engine => '/authorities'
  mount Hyrax::Engine, at: '/'
  resources :welcome, only: 'index'
  root 'hyrax/homepage#index'
  curation_concerns_basic_routes
  concern :exportable, Blacklight::Routes::Exportable.new

  # Mount sidekiq web ui and require authentication by an admin user

  authenticate :user, ->(u) { u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
    get 'csv_import_details/index'
    get 'csv_import_details/show/:id', to: 'csv_import_details#show', as: 'csv_import_detail'
  end

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
