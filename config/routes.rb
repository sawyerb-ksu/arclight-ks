# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
Rails.application.routes.draw do
  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  mount Blacklight::Engine => '/'
  mount BlacklightDynamicSitemap::Engine => '/'
  mount Arclight::Engine => '/'

  require 'sidekiq/web'
  mount Sidekiq::Web => '/queues'

  # DUL CUSTOMIZATION: note that component URLs have underscores; collections don't
  def collection_slug_constraint
    /[a-z0-9\-]+/
  end

  # DUL CUSTOMIZATION: homepage
  root to: 'pages#home'

  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
    concerns :range_searchable

    # concerns :range_searchable
  end
  devise_for :users

  concern :exportable, Blacklight::Routes::Exportable.new
  concern :hierarchy, Arclight::Routes::Hierarchy.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :hierarchy
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end
  # rubocop:enable Metrics/BlockLength

  resources :ua_record_groups, only: [:index], as: 'ua_record_groups', path: '/collections/ua-record-groups',
                               controller: 'ua_record_groups'

  # DUL CUSTOMIZATION: Download the source EAD XML file using the collection slug
  get '/catalog/:id/xml', action: 'ead_download', controller: 'catalog', as: 'ead_download',
                          constraints: { id: collection_slug_constraint }

  # DUL CUSTOMIZATION: Render a sitemap on-the-fly from a query (if configured)
  get '/custom_sitemaps/:id', controller: 'custom_sitemaps', action: 'index', defaults: { format: 'xml' },
                              constraints: ->(request) { CUSTOM_SITEMAP_CONFIG.key?(request.params[:id]) }

  post '/index_finding_aids', to: 'index_finding_aids#create'

  # Default health check introduced in Rails 7.1
  get 'up', to: 'rails/health#show', as: :rails_health_check
end
