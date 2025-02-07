# frozen_string_literal: true

# Overrides default Blacklight b/c as of 8.4.0 it breaks keyboard nav for the
# skip links. We also add data-turbo="false", which is required. Remove in future if fixed.
# https://github.com/projectblacklight/blacklight/blob/release-8.x/app/components/blacklight/skip_link_component.rb
class SkipLinkComponent < Blacklight::SkipLinkComponent
  def link_to_search
    link_to t('blacklight.skip_links.search_field'), '#search_field', class: link_classes, data: { turbo: 'false' }
  end

  def link_to_main
    link_to t('blacklight.skip_links.main_content'), '#main-container', class: link_classes, data: { turbo: 'false' }
  end
end
