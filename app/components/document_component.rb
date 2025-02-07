# frozen_string_literal: true

# Extend ArcLight's DocumentComponent
# https://github.com/projectblacklight/arclight/blob/main/app/components/arclight/document_component.rb
class DocumentComponent < Arclight::DocumentComponent
  # Use the DUL CUSTOM OnlineContentFilterComponent
  def online_filter
    render OnlineContentFilterComponent.new(document:)
  end
end
