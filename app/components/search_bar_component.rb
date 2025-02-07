# frozen_string_literal: true

# Extend ArcLight's SearchBarComponent
# https://github.com/projectblacklight/arclight/blob/main/app/components/arclight/search_bar_component.rb
# https://github.com/projectblacklight/blacklight/blob/main/app/components/blacklight/search_bar_component.rb
class SearchBarComponent < Arclight::SearchBarComponent
  # DUL CUSTOMIZATION: use the shorter collection_title (which is what we facet on)
  # instead of collection_name (which has the dates appended)
  def collection_name
    @collection_name ||= Array(@params.dig(:f, :collection)).reject(&:empty?).first ||
                         helpers.current_context_document&.collection_title&.first
  end
end
