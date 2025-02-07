# frozen_string_literal: true

# A component to encapsulate homepage-specific behavior
class HomepageComponent < ViewComponent::Base
  def initialize(blacklight_config:)
    super

    @blacklight_config = blacklight_config
  end

  attr_reader :blacklight_config

  def search_bar_component
    SearchBarComponent.new(
      url: helpers.search_action_url,
      advanced_search_url: helpers.search_action_url(action: 'advanced_search'),
      params: helpers.search_state.params_for_search.except(:qt),
      autocomplete_path: suggest_index_catalog_path
    )
  end

  def config_features
    @config_features ||= begin
      YAML.safe_load_file(config_filename)
    rescue Errno::ENOENT
      {}
    end
  end

  def config_filename
    Rails.root.join('config/featured_images.yml')
  end

  def random_feature
    img_index = config_features['image_list'].keys.sample
    config_features['image_list'][img_index]
  end

  # Image can be an absolute URL to any external image, or alternatively,
  # a name of a local file within assets/images/homepage
  def feature_img_url(image)
    return image if image.match(/^#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}$/)

    image_url(['homepage', image].join('/'))
  end

  def collection_count
    search_service = Blacklight.repository_class.new(blacklight_config)
    query = search_service.search(
      q: 'level_ssim:Collection',
      rows: 0
    )
    query.response['numFound']
  end
end
