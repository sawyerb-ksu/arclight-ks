# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'UA Record Groups' do
  describe 'UA Record Groups page' do
    before do
      visit '/collections/ua-record-groups'
    end

    it 'lists UA record groups with links to the facet' do
      expect(page).to have_link('Student/Campus Life',
                                href: '/catalog?f%5Bua_record_group_ssim%5D%5B%5D=31+--+Student%2FCampus+Life')
    end

    it 'lists UA record group subgroups with links to the facet' do
      expect(page).to have_link('Student Organizations - Recreational Sports',
                                href: '/catalog?f%5Bua_record_group_ssim%5D%5B%5D=31+--+' \
                                      'Student%2FCampus+Life+%3E+11+--+Student+Organizations+-+Recreational+Sports')
    end
  end

  describe 'UA collection page' do
    let(:doc_id) { 'uaduketaekwondo' }

    before do
      visit solr_document_path(id: doc_id)
    end

    it 'links UA record group to the corresponding facet' do
      expect(page).to have_link('31 -- Student/Campus Life',
                                href: '/catalog?f%5Bua_record_group_ssim%5D%5B%5D=31+--+Student%2FCampus+Life')
    end

    it 'links UA record subgroup to the corresponding facet' do
      expect(page).to have_link('31 -- Student/Campus Life > 11 -- Student Organizations - Recreational Sports',
                                href: '/catalog?f%5Bua_record_group_ssim%5D%5B%5D=31+--+' \
                                      'Student%2FCampus+Life+%3E+11+--+Student+Organizations+-+Recreational+Sports')
    end
  end
end
