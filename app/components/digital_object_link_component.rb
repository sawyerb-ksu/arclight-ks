# frozen_string_literal: true

# DUL CUSTOM COMPONENT. Render a simple link for a generic DAO
class DigitalObjectLinkComponent < ViewComponent::Base
  def initialize(object:)
    super

    @object = object
  end
end
