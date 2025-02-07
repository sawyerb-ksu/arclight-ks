# frozen_string_literal: true

# Extend ArcLight's CollectionInfoComponent. We revise the style and add
# some DUL-custom info in the dropdown.
# https://github.com/projectblacklight/arclight/blob/main/app/components/arclight/collection_info_component.rb
class CollectionInfoComponent < Arclight::CollectionInfoComponent
  delegate :ark,
           :bibnums,
           :collection_name,
           :collection_title,
           :collection_id,
           :online_item_count,
           :permalink,
           :title, to: :collection

  private

  def catalog_item_url(bibnum)
    ['https://find.library.duke.edu/catalog/DUKE', bibnum].join
  end
end
