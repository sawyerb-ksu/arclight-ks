# frozen_string_literal: true

# Application-wide helper behaviors
module ApplicationHelper
  def additional_locale_routing_scopes
    [blacklight, arclight_engine]
  end
end
