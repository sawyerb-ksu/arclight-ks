# frozen_string_literal: true

# Local extensions to:
# https://github.com/projectblacklight/arclight/blob/main/app/models/concerns/arclight/catalog.rb
#
module DulArclight
  ##
  # DUL-ArcLight specific methods for the Catalog Controller
  module Catalog
    extend ActiveSupport::Concern
    include Arclight::Catalog

    # DUL CUSTOMIZATION: send the source EAD XML file that we already have on the filesystem
    # Modeled after "raw" in BL core, see:
    # https://github.com/projectblacklight/blacklight/blob/main/app/controllers/concerns/blacklight/catalog.rb#L57-L63
    def ead_download
      @document = search_service.fetch(params[:id])
      send_file(
        ead_file_path,
        filename: "#{params[:id]}.xml",
        disposition: 'inline',
        type: 'text/xml'
      )
    end

    private

    def ead_file_path
      "#{DulArclight.finding_aid_data}/ead/#{repo_id}/#{params[:id]}.xml"
    end

    def repo_id
      @document&.repository_config&.slug
    end
  end
end
