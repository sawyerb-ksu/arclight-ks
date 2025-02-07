# frozen_string_literal: true

# DUL CUSTOMIZATION: Digital Objects component modeled loosely on ArcLight core's
# EmbedComponent, but with some customizations for DUL's needs. See:
# https://github.com/projectblacklight/arclight/blob/main/app/components/arclight/embed_component.rb
class DigitalObjectComponent < ViewComponent::Base
  def initialize(document:, presenter:, **kwargs)
    super

    @document = document
    @presenter = presenter
  end

  def render?
    resources.any?
  end

  def resources
    @resources ||= @document.digital_objects || []
  end

  def ddr_embeddable_resources
    resources.select { |object| object.role&.in?(ddr_embeddable_dao_roles) }
  end

  # Which DAO @role values should render an iframe with embedded DDR viewer?
  def ddr_embeddable_dao_roles
    %w[
      audio-streaming
      image-service
      video-streaming
    ]
  end

  # For now, a DDR digital object is determined by an href attribute
  # with hostname idn.duke.edu or repository.duke.edu & is not a collection.
  def ddr_dao_count
    all_ddr_daos.count
  end

  def all_ddr_daos
    resources.select { |object| ddr_url?(object.href) }.reject { |object| ddr_collection_objects.include? object }
  end

  def multiple_ddr_daos?
    ddr_dao_count > 1
  end

  def non_ddr_digital_objects
    resources - all_ddr_daos
  end

  def ddr_collection_objects
    resources.select { |object| object.role == 'ddr-collection-object' }
  end

  def erec_digital_objects
    resources.select { |object| object.role&.start_with?('electronic-record') }
  end

  def ddr_lookup_digital_objects
    resources.select { |object| object.role == 'ddr-item-lookup' }
  end

  def ddr_url?(href)
    url_regex = %r{\Ahttps?://(idn\.duke\.edu|repository\.duke\.edu)/}i
    href&.match?(url_regex)
  end

  # Link to a DDR search result (used with multiple DDR DAOs on a component)
  # Works with either EAD ID (esp. for collection-level DAOs) or component ID.
  def ddr_dao_search_result_link(document)
    ['https://repository.duke.edu/catalog?f%5Bead_id_ssi%5D%5B%5D=',
     document&.eadid,
     '&f%5Baspace_id_ssi%5D%5B%5D=',
     document&.reference&.sub('aspace_', '')].join
  end

  # DAOs that don't have any special handling -- just render links for these
  def simple_link_digital_objects
    resources - ddr_embeddable_resources - erec_digital_objects - ddr_lookup_digital_objects
  end
end
