# frozen_string_literal: true

# Sitemap XML from a query (for targeted harvesters)
class CustomSitemapsController < ApplicationController
  def index
    docs = fetch_docs.dig(:response, :docs)
    render_sitemap(docs)
  end

  private

  # rubocop:disable Metrics/MethodLength
  def render_sitemap(docs)
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.urlset(xmlns: 'http://www.sitemaps.org/schemas/sitemap/0.9') do
        docs.each do |doc|
          xml.url do
            xml.loc absolute_url(doc[:id])
            xml.lastmod doc[:timestamp]
          end
        end
      end
    end
    render xml: builder.to_xml
  end
  # rubocop:enable Metrics/MethodLength

  def absolute_url(id)
    url_for(action: 'show', controller: 'catalog', id:)
  end

  def fetch_docs
    search_service.search(
      fq: [configured_query, 'level_ssim:Collection'],
      fl: 'id, timestamp',
      facet: 'false',
      sort: 'timestamp desc',
      rows: '50000'
      # Sitemaps cannot exceed 50,000 entries per sitemaps.org standard.
    )
  end

  def search_service
    Blacklight.repository_class.new(blacklight_config)
  end

  def configured_query
    CUSTOM_SITEMAP_CONFIG.dig(params[:id], 'query')
  end
end
