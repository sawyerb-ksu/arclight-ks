# frozen_string_literal: true

# Extend ArcLight's SidebarComponent. We use a custom CollectionContextComponent
# and CollectionSidebarComponent.
# https://github.com/projectblacklight/arclight/blob/main/app/components/arclight/sidebar_component.rb
class SidebarComponent < Arclight::SidebarComponent
  def collection_context
    render CollectionContextComponent.new(presenter: document_presenter(document),
                                          download_component: Arclight::DocumentDownloadComponent)
  end

  def collection_sidebar
    render CollectionSidebarComponent.new(document:,
                                          collection_presenter: document_presenter(document.collection),
                                          partials: blacklight_config.show.metadata_partials)
  end
end
