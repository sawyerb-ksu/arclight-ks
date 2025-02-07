# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Group by collection customization', :js do
  context 'when searching from collection' do
    it 'does not group by collection' do
      visit solr_document_path(id: 'uaduketaekwondo')
      fill_in 'q', with: 'durham'
      click_on 'search'
      expect(page.current_url).not_to include('group=true')
    end
  end

  context 'when searching from collection but switching search scope to all' do
    it 'groups by collection' do
      visit solr_document_path(id: 'uaduketaekwondo')
      fill_in 'q', with: 'durham'
      select('All Collections', from: 'within_collection')
      click_on 'search'
      expect(page.current_url).to include('group=true')
    end
  end
end
