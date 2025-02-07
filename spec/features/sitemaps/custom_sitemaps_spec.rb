# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable RSpec/MultipleExpectations
RSpec.describe 'Custom sitemap' do
  context 'with an NLM URL for a configured query-based sitemap' do
    before do
      visit '/custom_sitemaps/nlm_history_of_medicine.xml'
    end

    it 'returns a sitemaps.org compliant sitemap' do
      xml = page.body
      expect(xml).to match(/<\?xml version="1.0"/)
      expect(xml).to match(/<url>/)
      expect(xml).to match(/<lastmod>/)
    end

    it 'includes HOM collections but not others' do
      xml = page.body
      expect(xml).to match(%r{catalog/trent-pasteurlouispapers</loc>})
      expect(xml).not_to match(%r{catalog/25under25</loc>})
    end
  end

  context 'with a Rubenstein+UA URL for a configured query-based sitemap' do
    before do
      visit '/custom_sitemaps/rubenstein_ua.xml'
    end

    it 'returns a sitemaps.org compliant sitemap' do
      xml = page.body
      expect(xml).to match(/<\?xml version="1.0"/)
      expect(xml).to match(/<url>/)
      expect(xml).to match(/<lastmod>/)
    end

    it 'includes RL & UA collections but not ADF' do
      xml = page.body
      expect(xml).to match(%r{catalog/trent-pasteurlouispapers</loc>})
      expect(xml).to match(%r{catalog/uaduketaekwondo</loc>})
      expect(xml).not_to match(%r{catalog/adfhalprinanna</loc>})
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations
