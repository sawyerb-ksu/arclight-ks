# frozen_string_literal: true

# Extend ArcLight's CollectionContextComponent. We revise the style and add
# some DUL-custom info in the dropdown. We also add the current document
# (which may be a component) to the context so we can display the container
# in the Request UI.
# https://github.com/projectblacklight/arclight/blob/main/app/components/arclight/collection_context_component.rb
class CollectionContextComponent < Arclight::CollectionContextComponent
  def initialize(presenter:, download_component:)
    super
    @document = presenter.document
  end

  attr_reader :document

  # We use the shorter title instead of normalized title
  def title
    collection.title.first
  end

  def collection_info
    render CollectionInfoComponent.new(collection:)
  end

  def duke_request
    render DukeRequestComponent.new(collection:, document:)
  end
end
