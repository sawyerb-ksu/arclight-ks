# frozen_string_literal: true

# DUL CUSTOMIZATION: helpers for rendering values for certain fields. See
# https://github.com/projectblacklight/arclight/blob/main/app/helpers/arclight/field_config_helpers.rb
# rubocop:disable Rails/OutputSafety
module FieldConfigHelpers
  # Render any URLs as live links
  def render_links(args)
    options = args[:config].try(:separator_options) || {}
    values = args[:value] || []

    values.map do |value|
      auto_link(value)
    end.to_sentence(options).html_safe
  end

  # Use singular form of descriptors for extents like "1 boxes", "1 folders", or "1 albums".
  # ASpace output frequently produces such strings.
  def singularize_extent(args)
    options = args[:config].try(:separator_options) || {}
    values = args[:value] || []
    values.map! do |value|
      correct_singular_value(value)
    end.to_sentence(options).html_safe
  end

  def correct_singular_value(value)
    chars_before_space = value.match(/([^\s]+)/)
    %w[1 1.0].include?(chars_before_space.to_s) ? value.singularize : value
  end

  def link_to_all_restrictions(_args)
    link_to 'More about accessing and using these materials...',
            '#using-these-materials',
            class: 'fw-semibold'
  end

  def render_using_these_materials_header(_args)
    render 'catalog/using_header'
  end

  def truncate_restrictions_teaser(args)
    values = args[:value] || []
    teaser = truncate(strip_tags(values.join(' ')), length: 200, separator: ' ')
    [teaser, link_to_all_restrictions(nil)].join('<br/>').html_safe
  end

  # Sometimes we really just want to return an array and not use Blacklight's default
  # Array#to_sentence ... e.g., for our JSON-API responses at catalog.json
  def keep_raw_values(args)
    args[:value] || []
  end
end
# rubocop:enable Rails/OutputSafety
