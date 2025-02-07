# frozen_string_literal: true

# Modeled loosely on existing ArcLight core requests:
# https://github.com/projectblacklight/arclight/blob/master/app/models/arclight/requests/google_form.rb
# https://github.com/projectblacklight/arclight/blob/master/app/models/arclight/requests/aeon_web_ead.rb

# A Request button that links to the Duke Catalog Request System
class DukeRequestComponent < ViewComponent::Base
  # @param collection [SolrDocument] for the collection
  def initialize(collection:, document:)
    super

    @collection = collection
    @document = document
  end

  attr_reader :collection, :document

  # Base url of request link
  def base_request_url
    'https://requests.library.duke.edu/item/'
  end

  # Full url of request link
  def duke_request_url
    [base_request_url, collection.bibnums.first].join
  end

  def one_bibnum?
    collection.bibnums&.count == 1
  end

  def multiple_bibnums?
    collection.bibnums&.count&.> 1
  end

  def request_btn_classes
    'btn btn-success btn-block fw-bold flex-grow-1'
  end

  # Catalog SERP result URL (for cases w/2+ bib numbers)
  def catalog_serp_url
    ['https://find.library.duke.edu/?search_field=isbn_issn&q=', collection.eadid].join
  end

  def request_tooltip
    tooltips = [I18n.t('dul_arclight.views.show.sidebar.request.tooltip')]
    tooltips << I18n.t('dul_arclight.views.show.sidebar.request.multi_bib') if multiple_bibnums?
    if document.containers.present?
      tooltips << I18n.t('dul_arclight.views.show.sidebar.request.current_containers',
                         containers: document.containers.join(', '))
    end
    tooltips.join('<br/><br/>')
  end
end
