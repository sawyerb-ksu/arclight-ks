# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Advanced Search' do
  # rubocop:disable RSpec/ExampleLength
  context 'when searching name and location' do
    it 'combines searches in different fields' do
      visit '/catalog/advanced'
      fill_in 'clause_1_query', with: 'thornton'
      fill_in 'clause_2_query', with: 'philadelphia'
      click_on 'advanced-search-submit'

      expect(page).to have_css(
        "header[data-document-id='rushbenjaminandjulia_aspace_e8c931bd1a705ee75fdd0c75c5ad45a5']"
      )
    end
  end
  # rubocop:enable RSpec/ExampleLength
end
