# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Collection page Contents section', :js do
  describe 'when on a collection show page' do
    it 'renders a Contents section' do
      visit solr_document_path(id: 'rushbenjaminandjulia')
      expect(page).to have_css('div#contents')
    end

    it 'renders a link to each top level series' do
      visit solr_document_path(id: 'rushbenjaminandjulia')
      click_on 'Contents'
      expect(page).to have_css('turbo-frame .table-striped a', text: 'Letters, 1777-1824')
    end
  end
end
