# frozen_string_literal: true

# Extend ArcLight's OnlineStatusIndicatorComponent to add a tooltip & role.
# https://github.com/projectblacklight/arclight/blob/main/app/components/arclight/online_status_indicator_component.rb
class OnlineStatusIndicatorComponent < Arclight::OnlineStatusIndicatorComponent
  def call
    tag.span helpers.blacklight_icon(:online),
             class: 'al-online-content-icon',
             title: 'Available online or by request',
             role: 'img',
             data: { bs_toggle: 'tooltip' }
  end
end
