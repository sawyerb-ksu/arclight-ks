# frozen_string_literal: true

# Represents a single document returned from Solr
# See https://github.com/projectblacklight/arclight/blob/main/app/models/concerns/arclight/solr_document.rb
class SolrDocument
  include Blacklight::Solr::Document
  include Arclight::SolrDocument
  include ActionView::Helpers::TextHelper # for short description
  include FieldConfigHelpers # for correct_singular_value
  require 'dul_arclight/digital_object'

  attribute :accessrestrict, :array, 'accessrestrict_html_tesm'
  attribute :userestrict, :array, 'userestrict_html_tesm'
  attribute :physdesc, :array, 'physdesc_tesim'
  attribute :phystech, :array, 'phystech_html_tesm'
  attribute :accessrestrict_collection_banner, :array, 'accessrestrict_collection_banner_html_tesm'

  # self.unique_key = 'id'

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core

  # DUL CUSTOMIZATION: turn this off, as it exposes undesired .xml, .dc_xml, and .oai_dc_xml
  # URLs using link rel="alternate" in the HTML head.
  # use_extension(Blacklight::Document::DublinCore)

  # DUL CUSTOMIZATION: ARK & Permalink
  def ark
    fetch('ark_ssi', '')
  end

  def permalink
    fetch('permalink_ssi', '')
  end

  # DUL CUSTOMIZATION: get the non-prefixed ArchivesSpace ID for a component.
  # esp. for digitization guide / DDR import starter from bookmark export.
  def aspace_id
    fetch('ref_ssi', '').delete_prefix('aspace_')
  end

  def bibnums
    fetch('bibnum_ssim', [])
  end

  # DUL-specific language display logic: If there's at least one <langmaterial> with no
  # child <language>, use that/those. Fall back to using langmaterial/language values.
  def languages
    fetch('langmaterial_ssim') { fetch('language_ssim', []) }
  end

  # We need this method for links to narrow results within collection b/c
  # collection_name has the normalized title with dates appended, but the
  # facet value is just the title. TBD: is this an arclight core bug?
  def collection_title
    fetch('collection_ssim', [])
  end

  # DUL custom property for a tagless short description of a collection or component.
  # Can be used e.g., in meta tags or popovers/tooltips.
  def short_description
    truncate(strip_tags(abstract_or_scope), length: 400, separator: ' ')
  end

  # DUL CUSTOMIZATION: title, esp. for easy access to the basic collection
  # title without the dates that are appended in the normalized title.
  def title
    fetch('title_ssm', '')
  end

  def digital_objects
    digital_objects_field = fetch('digital_objects_ssm', []).reject(&:empty?)
    return [] if digital_objects_field.blank?

    digital_objects_field.map do |object|
      DulArclight::DigitalObject.from_json(object)
    end
  end

  def ddr_collection_objects
    digital_objects.select { |object| object.role == 'ddr-collection-object' }
  end

  def component?
    parent_ids.present?
  end

  def restricted_component?
    component? && (accessrestrict.present? || userestrict.present? || phystech.present?)
  end

  def ancestor_context
    parent_labels.join(' > ') unless level == 'collection'
  end

  def ancestor_context_with_label
    ['In:', ancestor_context].join(' ') if ancestor_context.present?
  end

  def meta_tag_description
    [ancestor_context_with_label, short_description].compact.join(' // ')
  end

  # Find the Series title by reconciling the arrays of parent labels & parent levels
  # NOTE: this method exists primarily for CSV exports of bookmarks for starter
  # digitization guides & batch metadata upload to DDR.
  def series_title
    i = parent_levels.find_index('Series')
    parent_labels[i] if i.present?
  end

  # Find the Subseries title by reconciling the arrays of parent labels & parent levels
  # NOTE: this method exists primarily for CSV exports of bookmarks for starter
  # digitization guides & batch metadata upload to DDR.
  def subseries_title
    i = parent_levels.find_index('Subseries')
    parent_labels[i] if i.present?
  end
end
