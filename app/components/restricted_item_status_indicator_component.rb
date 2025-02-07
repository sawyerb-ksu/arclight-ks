# frozen_string_literal: true

# DUL CUSTOM component to display a warning icon for restricted items.
# Inspired by Arclight core's OnlineStatusIndicatorComponent, see:
# https://github.com/projectblacklight/arclight/blob/main/app/components/arclight/online_status_indicator_component.rb
class RestrictedItemStatusIndicatorComponent < Blacklight::Component
  def initialize(document:, **)
    @document = document
    super
  end

  def render?
    @document.restricted_component?
  end

  def call
    tag.span helpers.blacklight_icon(:restricted_item),
             class: 'al-restricted-status-icon',
             title: 'Some restrictions apply',
             role: 'img',
             data: { bs_toggle: 'tooltip' }
  end
end
