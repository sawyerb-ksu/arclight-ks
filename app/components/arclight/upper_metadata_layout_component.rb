# frozen_string_literal: true

# DUL CUSTOMIZATION: Override upstream arclight in order to remove
# the columnized layout for metadata definition lists. See:
# https://github.com/projectblacklight/arclight/blob/main/app/components/arclight/upper_metadata_layout_component.rb
module Arclight
  # We provide our own label_class & value_class.
  class UpperMetadataLayoutComponent < Blacklight::MetadataFieldLayoutComponent
    def initialize(field:, label_class: 'col-12', value_class: 'col-12')
      super
    end
  end
end
