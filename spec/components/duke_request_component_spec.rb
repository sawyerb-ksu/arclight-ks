# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Capybara/SpecificMatcher
# The have_link matcher doesn't seem to work in a Capybara node, so we
# intentionally use have_selector.
RSpec.describe DukeRequestComponent, type: :component do
  subject(:component) { described_class.new(**params) }

  let(:rendered) { Capybara::Node::Simple.new(render_inline(component)) }
  let(:params) { { collection:, document: } }

  context 'with one Bib ID present' do
    let(:collection) { instance_double(SolrDocument, bibnums: ['123']) }
    let(:document) { instance_double(SolrDocument, containers: ['Box MN6']) }

    it 'renders a link to the request form' do
      expect(rendered).to have_css('a[href="https://requests.library.duke.edu/item/123"]')
    end

    it 'puts the container info in the button title for use by the tooltip' do
      expect(rendered).to have_css('a[title*="Box MN6"]')
    end
  end

  context 'with multiple Bib IDs present' do
    let(:collection) do
      instance_double(SolrDocument,
                      bibnums: %w[123 456],
                      eadid: 'rushbenjaminandjulia')
    end
    let(:document) { instance_double(SolrDocument, containers: []) }

    it 'returns a link to a catalog search result searching the eadid' do
      expect(rendered).to have_css('a[href="https://find.library.duke.edu/?search_field=isbn_issn&q=rushbenjaminandjulia"]')
    end
  end
end
# rubocop:enable Capybara/SpecificMatcher
