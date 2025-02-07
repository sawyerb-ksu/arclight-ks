# frozen_string_literal: true

# Helpers for sending data to Matomo, especially custom
# dimensions for tracking by page type and collection slug
# rubocop:disable Rails/HelperInstanceVariable, Metrics/MethodLength
module MatomoAnalyticsHelper
  # Matomo Analytics Custom Dimensions.
  # These are logged with every pageview and custom Event.
  # https://matomo.org/guide/reporting-tools/custom-dimensions/

  def matomo_collection_id
    @document&.eadid
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def matomo_page_type
    if search_results_page_zero_results?
      'No Results Page'
    elsif search_results_page_with_results?
      'Search Results Page'
    elsif home_page?
      'Homepage'
    elsif collection_show_page?
      'Collection Page'
    elsif component_show_page?
      'Component Page'
    elsif bookmarks_page?
      'Bookmarks Page'
    elsif ua_record_groups_page?
      'UA Record Groups Page'
    else
      'Other Page'
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  private

  def search_results_page_with_results?
    search_results_page? && response_has_results?
  end

  def search_results_page_zero_results?
    search_results_page? && !response_has_results?
  end

  def home_page?
    catalog_controller? && controller.action_name == 'index' \
      && respond_to?(:has_search_parameters?) && !has_search_parameters?
  end

  def collection_show_page?
    catalog_controller? && controller.action_name == 'show' \
      && @document&.level == 'collection'
  end

  def component_show_page?
    catalog_controller? && controller.action_name == 'show' \
      && @document&.level != 'collection'
  end

  def search_results_page?
    catalog_controller? && controller.action_name == 'index' \
      && respond_to?(:has_search_parameters?) && has_search_parameters?
  end

  def ua_record_groups_page?
    controller.controller_name == 'ua_record_groups'
  end

  def bookmarks_page?
    controller.controller_name == 'bookmarks'
  end

  def catalog_controller?
    controller.controller_name == 'catalog'
  end

  def response_has_results?
    @response.present? && @response.respond_to?(:total) \
      && @response.total.positive?
  end
end
# rubocop:enable Rails/HelperInstanceVariable, Metrics/MethodLength
