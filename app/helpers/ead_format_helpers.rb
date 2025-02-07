# frozen_string_literal: true

# DUL CUSTOMIZATION: Override or extend EAD formatting methods from Arclight engine.
# TODO: We may be able to remove this entirely if archref gets accounted for at the
# core level per https://github.com/projectblacklight/arclight/issues/1461
# See:
# https://github.com/projectblacklight/arclight/blob/main/app/helpers/arclight/ead_format_helpers.rb
module EadFormatHelpers
  include Arclight::EadFormatHelpers

  private

  # Overrides arclight core method in order to call the DUL-custom methods below
  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
  def ead_to_html_scrubber
    Loofah::Scrubber.new do |node|
      format_render_attributes(node) if node.attr('render').present?
      convert_to_span(node) if CONVERT_TO_SPAN_TAGS.include? node.name
      convert_to_br(node) if CONVERT_TO_BR_TAG.include? node.name
      # DUL CUSTOMIZATION: format_archrefs
      format_archrefs(node) if %w[archref].include? node.name
      format_links(node) if %w[extptr extref extrefloc ptr ref].include? node.name
      format_lists(node) if %w[list chronlist].include? node.name
      format_indexes(node) if node.name == 'index'
      format_tables(node) if node.name == 'table'
      node
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

  # Format references to other finding aids
  def format_archrefs(node)
    # If an archref has sibling archrefs, grab all of them as a nodeset, wrap
    # them in a <ul> & wrap each item in an <li>. Seems odd but common for such
    # encoding to imply a list. See https://www.loc.gov/ead/tglib/elements/archref.html
    archref_sibs = node.xpath('./self::archref | ./following-sibling::archref')
    if archref_sibs.count > 1
      archref_sibs.first.previous = '<ul/>'
      archref_sibs.map do |a|
        a.parent = a.previous_element
        a.wrap('<li/>')
      end
    end
    format_archref_repos(node)
  end

  # Format <repository> element within an archref (probably DUL-specific)
  def format_archref_repos(node)
    archref_repos = node.xpath('.//repository')
    archref_repos&.map do |r|
      r.name = 'em'
      r.prepend_child(' - ')
    end
  end

  CONVERT_TO_SPAN_TAGS = ['title'].freeze
  CONVERT_TO_BR_TAG = ['lb'].freeze
end
