# frozen_string_literal: true

# DUL CUSTOMIZATION: Override upstream arclight in order to remove
# the columnized layout for metadata definition lists. See:
# https://github.com/projectblacklight/arclight/blob/main/app/components/arclight/metadata_section_component.rb
module Arclight
  # Render a simple metadata field (e.g. without labels) in a div
  # By default in 1.0 this is a .row div, but we remove .row here
  class MetadataSectionComponent < ViewComponent::Base
    with_collection_parameter :section

    def initialize(section:, presenter:, metadata_attr: {}, classes: %w[], heading: false)
      super

      @classes = classes
      @section = section
      @presenter = presenter.with_field_group(section)
      @heading = heading
      @metadata_attr = metadata_attr
    end

    def render?
      @presenter.fields_to_render.any?
    end
  end
end
