# frozen_string_literal: true

# DUL CUSTOM controller for the bookmarks page. We use this to configure tools
# e.g., CSV export & email, that are different from default search results pages.
class BookmarksController < CatalogController
  include Blacklight::Bookmarks

  configure_blacklight do |config|
    # DUL CUSTOMIZATION: Add CSV export for bookmarks
    config.add_results_collection_tool(:export_csv, partial: 'export_csv_button')

    # DUL CUSTOMIZATION: Add email tool for bookmarks. Both of these configs seem to be
    # required to get emails to work, counterintuitively.
    config.add_show_tools_partial(:email, callback: :email_action, validator: :validate_email_params)
    config.add_results_collection_tool(:email, partial: 'bookmarks/email_button')
  end
end
