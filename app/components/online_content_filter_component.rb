# frozen_string_literal: true

# Extend ArcLight's OnlineContentFilterComponent
# https://github.com/projectblacklight/arclight/blob/main/app/components/arclight/online_content_filter_component.rb
class OnlineContentFilterComponent < Arclight::OnlineContentFilterComponent
  attr_reader :document

  delegate :collection_title,
           :ddr_collection_objects,
           :digital_objects,
           :online_content?,
           :online_item_count, to: :document

  def render?
    @document.collection? && (online_content? || ddr_collection_objects.present?)
  end

  # Does the collection have individual online items beyond a DDR collection link?
  def render_filter_link?
    online_item_count.to_i > ddr_collection_objects.count
  end
end
