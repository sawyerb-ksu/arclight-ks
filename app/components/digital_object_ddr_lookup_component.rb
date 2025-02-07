# frozen_string_literal: true

# DUL CUSTOM COMPONENT. From a DAO that has a DDR search result as its href,
# hit the catalog.json API endpoint to get the hit count for that search.
class DigitalObjectDdrLookupComponent < ViewComponent::Base
  def initialize(object:)
    super

    @object = object
  end

  # For a DDR search results URL DAO (ddr-item-lookup)
  # TODO: consider whether to make these requests client-side via AJAX.
  # Would need to revise CORS config for DDR JSON API endpoints to permit
  # cross-origin requests.
  # rubocop:disable Layout/LineLength, Metrics/MethodLength, Security/Open
  def ddr_query_hit_count
    response = Timeout.timeout(2) do
      URI.open(json_url_from_query).read
    end
    doc = JSON.parse(response)
    doc.dig('meta', 'pages', 'total_count')
  rescue Timeout::Error
    Rails.logger.error('DDR-Public API request timed out.')
    nil
  rescue OpenURI::HTTPError => e
    Rails.logger.error("DDR-Public API request returned an error. Note that this API is only reachable via permitted hosts/networks, which may not include the current environment: #{e.message}")
    nil
  rescue StandardError => e
    Rails.logger.error("An unexpected error occurred with the DDR-Public API request: #{e.message}")
    nil
  end
  # rubocop:enable Layout/LineLength, Metrics/MethodLength, Security/Open

  # Return a Blacklight catalog.json search results API URL from a UI search result URL.
  def json_url_from_query
    uri = URI(@object.href)
    uri.path << '.json'
    uri.to_s
  end
end
