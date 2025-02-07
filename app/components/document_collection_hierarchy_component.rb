# frozen_string_literal: true

# Extend ArcLight's DocumentCollectionHierarchyComponent
# https://github.com/projectblacklight/arclight/blob/main/app/components/arclight/document_collection_hierarchy_component.rb
class DocumentCollectionHierarchyComponent < Arclight::DocumentCollectionHierarchyComponent
  def restricted_status
    render RestrictedItemStatusIndicatorComponent.new(document: @document)
  end
end
