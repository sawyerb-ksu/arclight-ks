# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable RSpec/MultipleExpectations
RSpec.describe 'Blacklight dynamic sitemap' do
  context 'with a /sitemap URL' do
    it 'returns a sitemaps.org-compliant dynamic sitemap w/URLs to sub-sitemaps' do
      visit '/sitemap'
      xml = page.body
      expect(xml).to match(/<\?xml version="1.0"/)
      expect(xml).to match(%r{/sitemap/0</loc>})
      expect(xml).to match(%r{/sitemap/1</loc>})
    end
  end

  context 'with a sub-sitemap URL' do
    it 'returns a sitemaps.org-compliant dynamic sitemap w/collection URLs & lastmod dates' do
      visit '/sitemap/0'
      xml = page.body
      expect(xml).to match(/<\?xml version="1.0"/)
      expect(xml).to match(%r{/catalog/[a-z0-9\-]+</loc>})
      expect(xml).to match(/<lastmod>/)
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations
