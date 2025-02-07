# frozen_string_literal: true

# DUL CUSTOM COMPONENT. Render an Aeon request link for an electronic record DAO
class DigitalObjectErecComponent < ViewComponent::Base
  def initialize(object:, document:)
    super

    @object = object
    @document = document
  end

  # Temporary link to an Aeon request using OpenURL
  # https://support.atlas-sys.com/hc/en-us/articles/360011919573-Submitting-Requests-via-OpenURL
  # NOTE: this is only used for legacy electronic record DAOs and is
  # likely a stopgap until those can be refactored or migrated elsewhere.
  def erec_aeon_link
    base_url = 'https://duke.aeon.atlas-sys.com/logon/'
    [base_url, '?', aeon_params].join
  end

  # rubocop:disable Metrics/MethodLength
  def aeon_params
    params_with_values =
      {
        Action: '10',
        Form: '30',
        genre: 'manuscript',
        rfe_dat: ['Bib Record:', @document.bibnums&.first].join,
        # TODO: add accessrestrict here once available
        # 'rft.access': @document.accessrestrict.map { |r| strip_tags(r) }&.join(' '),
        'rft.au': @document.creator,
        'rft.barcode': @object.xpointer,
        'rft.callnum': @object.role,
        'rft.collcode': 'Electronic_Record',
        'rft.date': @document.normalized_date,
        'rft.eadid': @document.eadid,
        'rft.pub': @document.id,
        'rft.site': 'SCL',
        'rft.stitle': [@object.label, @document.extent].join(' -- '),
        'rft.title': @document.collection_name,
        'rft.volume': @object.href
      }.compact_blank
    params_with_values&.to_query
  end
  # rubocop:enable Metrics/MethodLength
end
