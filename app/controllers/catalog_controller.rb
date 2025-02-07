# frozen_string_literal: true

# Blacklight controller that handles searches and document requests
# rubocop:disable Metrics/ClassLength
class CatalogController < ApplicationController
  include Blacklight::Catalog
  include DulArclight::Catalog
  include BlacklightRangeLimit::ControllerOverride

  include Arclight::Catalog

  # DUL CUSTOMIZATION: Add collection-level restrictions field type for teaser box
  Blacklight::Configuration.define_field_access :collection_restrictions_teaser_field,
                                                Blacklight::Configuration::ShowField
  # DUL CUSTOMIZATION: Add special global banner restrictions field type
  Blacklight::Configuration.define_field_access :restrictions_banner_field, Blacklight::Configuration::ShowField
  # DUL CUSTOMIZATION: Add yellow component restrictions field type
  Blacklight::Configuration.define_field_access :component_restrictions_field, Blacklight::Configuration::ShowField
  # DUL CUSTOMIZATION: indexes field type
  Blacklight::Configuration.define_field_access :indexes_field, Blacklight::Configuration::ShowField
  # DUL CUSTOMIZATION: component indexes field type
  Blacklight::Configuration.define_field_access :component_indexes_field, Blacklight::Configuration::ShowField

  # rubocop:disable Metrics/BlockLength
  configure_blacklight do |config|
    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository
    #
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    # config.search_builder_class = ::SearchBuilder
    #
    ## Model that maps search index responses to the blacklight response model
    # config.response_model = Blacklight::Solr::Response

    ## Enable getting JSON at /raw endpoint
    config.raw_endpoint.enabled = true

    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    config.default_solr_params = {
      rows: 10,
      fl: '*,collection:[subquery]',
      'collection.q': '{!terms f=id v=$row._root_}',
      'collection.defType': 'lucene',
      'collection.fl': '*',
      'collection.rows': 1
    }

    # Sets the indexed Solr field that will display with highlighted matches
    config.highlight_field = 'text'

    # solr path which will be added to solr base url before the other solr params.
    # config.solr_path = 'select'

    # DUL CUSTOMIZATION: for native Advanced Search and any other feature that may
    # use JSON DSL queries, use our default /select searchHandler. Blacklight 8.1.0
    # sets this to /advanced -- see https://github.com/projectblacklight/blacklight/pull/3066
    # but that'd require defining a whole other set of rules for a new handler in solrconfig.xml
    # Consider refactoring in future.
    config.json_solr_path = 'select'

    # items to show per page, each number in the array represent another option to choose from.
    # config.per_page = [10,20,50,100]

    ## Default parameters to send on single-document requests to Solr.
    ## These settings are the Blacklight defaults (see SearchHelper#solr_doc_params) or
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    config.default_document_solr_params = {
      qt: 'document',
      fl: '*,collection:[subquery]',
      'collection.q': '{!terms f=id v=$row._root_}',
      'collection.defType': 'lucene',
      'collection.fl': '*',
      'collection.rows': 1
    }

    # DUL CUSTOMIZATION: custom header component
    config.header_component = HeaderComponent
    # DUL CUSTOMIZATION: custom online status component
    config.add_results_document_tool(:online, component: OnlineStatusIndicatorComponent)
    # DUL CUSTOMIZATION: custom restricted status component
    config.add_results_document_tool(:restricted_status, component:
      RestrictedItemStatusIndicatorComponent)
    # DUL CUSTOMIZATION: custom skip link component; remove if BL bug gets fixed
    config.skip_link_component = SkipLinkComponent

    config.add_results_document_tool(:arclight_bookmark_control, component: Arclight::BookmarkComponent)

    config.add_results_collection_tool(:group_toggle)
    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)

    # DUL CUSTOMIZATION: we don't need the list vs. compact view toggle
    # config.add_results_collection_tool(:view_type_group)

    config.add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
    config.add_nav_action(:search_history, partial: 'blacklight/nav/search_history')

    # DUL CUSTOMIZATION: CSV response especially for exporting
    # Bookmarks to a digitization guide.
    config.index.respond_to.csv = true

    # solr field configuration for search results/index views
    config.index.partials = %i[arclight_index_default]
    config.index.title_field = 'normalized_title_ssm'
    config.index.display_type_field = 'level_ssm'
    config.index.document_component = Arclight::SearchResultComponent
    config.index.group_component = Arclight::GroupComponent
    config.index.constraints_component = Arclight::ConstraintsComponent
    config.index.document_presenter_class = Arclight::IndexPresenter

    # DUL CUSTOMIZATION: custom search bar component
    config.index.search_bar_component = SearchBarComponent

    # config.index.thumbnail_field = 'thumbnail_path_ss'

    # solr field configuration for document/show views
    # config.show.title_field = 'title_display'
    # DUL CUSTOMIZATION: custom document component
    config.show.document_component = DocumentComponent

    # DUL CUSTOMIZATION: custom sidebar component
    config.show.sidebar_component = SidebarComponent

    # DUL CUSTOMIZATION: custom breadcrumb component
    config.show.breadcrumb_component = BreadcrumbsHierarchyComponent
    # DUL CUSTOMIZATION: custom embed component
    config.show.embed_component = DigitalObjectComponent
    config.show.access_component = Arclight::AccessComponent
    # DUL CUSTOMIZATION: custom online status component
    config.show.online_status_component = OnlineStatusIndicatorComponent
    config.show.display_type_field = 'level_ssm'
    # config.show.thumbnail_field = 'thumbnail_path_ss'
    config.show.document_presenter_class = Arclight::ShowPresenter

    # DUL CUSTOMIZATION: add fake contents_field here to display in
    # sidebar nav.
    config.show.metadata_partials = %i[
      restrictions_banner_field
      collection_restrictions_teaser_field
      summary_field
      background_field
      related_field
      indexed_terms_field
      indexes_field
      contents_field
      access_field
    ]

    config.show.collection_access_items = %i[
      terms_field
      in_person_field
      contact_field
      cite_field
    ]

    config.show.component_metadata_partials = %i[
      restrictions_banner_field
      component_restrictions_field
      component_field
      component_indexed_terms_field
      component_indexes_field
    ]

    config.show.component_access_items = %i[
      component_terms_field
      in_person_field
      contact_field
      cite_field
    ]

    ##
    # Compact index view
    config.view.compact!

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    #
    # set :index_range to true if you want the facet pagination view to have facet prefix-based navigation
    #  (useful when user clicks "more" on a large facet and wants to navigate alphabetically
    #  across a large set of results)
    # :index_range can be an array or range of prefixes that will be used to create the navigation
    #  (note: It is case sensitive when searching values)

    # DUL CUSTOMIZATION: Reordered facets, customized Access, added Format.
    config.add_facet_field 'access',
                           label: 'Digital Materials',
                           collapse: false,
                           query: {
                             online: { label: 'Includes Digital Materials', fq: 'has_online_content_ssim:true' }
                           }
    config.add_facet_field 'collection', field: 'collection_ssim', limit: 10
    config.add_facet_field 'creators', field: 'creator_ssim', limit: 10

    # DUL CUSTOMIZATION: use the blacklight_range_limit plugin for Date Range
    config.add_facet_field 'date_range', field: 'date_range_isim', range: true,
                                         range_config: {
                                           chart_segment_border_color: 'rgb(255, 217, 96)',
                                           chart_segment_bg_color: 'rgba(255, 217, 96, 0.5)',
                                           show_missing_link: false
                                         }

    config.add_facet_field 'level', field: 'level_ssim', limit: 10
    config.add_facet_field 'names', field: 'names_ssim', limit: 10
    config.add_facet_field 'repository', field: 'repository_ssim', limit: 10
    # DUL CUSTOMIZATION: Use places_ssim instead of geogname_ssim; the two fields
    # are currently redundant in arclight core.
    config.add_facet_field 'places', field: 'places_ssim', limit: 10
    config.add_facet_field 'access_subjects', field: 'access_subjects_ssim', limit: 10
    # DUL CUSTOMIZATION: Add Format facet.
    config.add_facet_field 'format', field: 'genreform_ssim', limit: 10

    # DUL CUSTOMIZATION: Add UA Record Group hierarchical facet.
    config.add_facet_field 'ua_record_group_ssim',
                           limit: -1,
                           label: 'University Archives Record Group',
                           component: Blacklight::Hierarchy::FacetFieldListComponent

    config.facet_display = {
      hierarchy: {
        'ua_record_group' => [['ssim'], ' > ']
      }
    }

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # Solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    # In ArcLight 1.x these are the fields that display in the UI AND that render
    # via the JSON-API response at catalog.json
    config.add_index_field 'highlight', accessor: 'highlights', separator_options: {
      words_connector: '<br/>',
      two_words_connector: '<br/>',
      last_word_connector: '<br/>'
    }, compact: true, component: Arclight::IndexMetadataFieldComponent

    # DUL CUSTOMIZATION: remove creator from index fields.
    # config.add_index_field 'creator', accessor: true, component: Arclight::IndexMetadataFieldComponent
    config.add_index_field 'abstract_or_scope', accessor: true, truncate: true, repository_context: true,
                                                helper_method: :render_html_tags,
                                                component: Arclight::IndexMetadataFieldComponent
    config.add_index_field 'breadcrumbs', accessor: :itself, component: Arclight::SearchResultBreadcrumbsComponent,
                                          compact: { count: 2 }

    # DUL CUSTOMIZATION: Here, we add index fields that we want to appear in the catalog.json
    # search results JSON-API response for our integrations with external systems (DDR, QuickSearch)
    # but that we DON'T want to appear in the search results UI.
    config.add_index_field 'normalized_title', accessor: true, label: 'Title',
                                               if: lambda { |controller, _config, _field|
                                                     controller.params['format'] == 'json'
                                                   }
    config.add_index_field 'short_description', accessor: true, label: 'Description',
                                                if: lambda { |controller, _config, _field|
                                                      controller.params['format'] == 'json'
                                                    }
    config.add_index_field 'creator', accessor: true, label: 'Creator',
                                      if: lambda { |controller, _config, _field|
                                            controller.params['format'] == 'json'
                                          }
    config.add_index_field 'parent_labels', accessor: true, label: 'In', helper_method: 'keep_raw_values',
                                            if: lambda { |controller, _config, _field|
                                                  controller.params['format'] == 'json'
                                                }
    config.add_index_field 'parent_ids', accessor: true, label: 'Ancestor IDs', helper_method: 'keep_raw_values',
                                         if: lambda { |controller, _config, _field|
                                               controller.params['format'] == 'json'
                                             }

    config.add_index_field 'level', accessor: true, label: 'Level',
                                    if: lambda { |controller, _config, _field|
                                          controller.params['format'] == 'json'
                                        }

    config.add_index_field 'extent', accessor: true, label: 'Extent',
                                     if: lambda { |controller, _config, _field|
                                           controller.params['format'] == 'json'
                                         }
    config.add_index_field 'containers', accessor: true, label: 'Containers',
                                         if: lambda { |controller, _config, _field|
                                               controller.params['format'] == 'json'
                                             }
    config.add_index_field 'collection_name', accessor: true, label: 'Collection',
                                              if: lambda { |controller, _config, _field|
                                                    controller.params['format'] == 'json'
                                                  }
    config.add_index_field 'eadid', accessor: true, label: 'EAD ID',
                                    if: lambda { |controller, _config, _field|
                                          controller.params['format'] == 'json'
                                        }
    config.add_index_field 'online_content?', accessor: true, label: 'Online Content',
                                              if: lambda { |controller, _config, _field|
                                                    controller.params['format'] == 'json'
                                                  }
    config.add_index_field 'component?', accessor: true, label: 'Component',
                                         if: lambda { |controller, _config, _field|
                                               controller.params['format'] == 'json'
                                             }
    config.add_index_field 'restricted_component?', accessor: true, label: 'Restrictions',
                                                    if: lambda { |controller, _config, _field|
                                                          controller.params['format'] == 'json'
                                                        }

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # DUL CUSTOMIZATION: Enable BL built-in Advanced Search by implementing the
    # workaround described here:
    # https://github.com/projectblacklight/blacklight/wiki/Advanced-Search#clause-params
    # I.e., for each add_search_field, we add a field.clause_params = { edismax: { ... } }
    # AND in our solrconfig.xml we set <luceneMatchVersion>7.1.0</luceneMatchVersion>.
    # TODO: this bug will be fixed in Solr 9.4 per https://issues.apache.org/jira/browse/SOLR-16916
    # so remove this workaround when we are able to upgrade to/beyond that version.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.
    config.add_search_field 'all_fields', label: 'All Fields' do |field|
      field.include_in_simple_select = true
      field.include_in_advanced_search = false
    end

    config.add_search_field 'within_collection' do |field|
      field.include_in_simple_select = false
      field.include_in_advanced_search = false
      field.solr_parameters = {
        fq: '-level_ssim:Collection'
      }
      field.clause_params = { edismax: field.solr_parameters.dup }
    end

    # Field-based searches. We have registered handlers in the Solr configuration
    # so we have Blacklight use the `qt` parameter to invoke them.

    # DUL CUSTOMIZATION note: We have 'all_fields' in simple select but not advanced,
    # and keyword is the opposite. This might seem strange but is related to the
    # https://github.com/projectblacklight/blacklight/wiki/Advanced-Search#clause-params
    # issue described above. We may be able to change this when we upgrade to Solr 9.4.
    config.add_search_field 'keyword', label: 'Keywords' do |field|
      field.include_in_simple_select = false
      field.include_in_advanced_search = true
      field.qt = 'search' # default
      field.solr_parameters = {
        qf: '${qf}',
        pf: '${pf}'
      }
      field.clause_params = { edismax: field.solr_parameters.dup }
    end
    config.add_search_field 'name', label: 'Name' do |field|
      field.qt = 'search'
      field.solr_parameters = {
        qf: '${qf_name}',
        pf: '${pf_name}'
      }
      field.clause_params = { edismax: field.solr_parameters.dup }
    end
    config.add_search_field 'place', label: 'Place' do |field|
      field.qt = 'search'
      field.solr_parameters = {
        qf: '${qf_place}',
        pf: '${pf_place}'
      }
      field.clause_params = { edismax: field.solr_parameters.dup }
    end
    config.add_search_field 'subject', label: 'Subject' do |field|
      field.qt = 'search'
      field.solr_parameters = {
        qf: '${qf_subject}',
        pf: '${pf_subject}'
      }
      field.clause_params = { edismax: field.solr_parameters.dup }
    end
    config.add_search_field 'format', label: 'Format' do |field|
      field.qt = 'search'
      field.solr_parameters = {
        qf: '${qf_format}',
        pf: '${pf_format}'
      }
      field.clause_params = { edismax: field.solr_parameters.dup }
    end
    config.add_search_field 'container', label: 'Container' do |field|
      field.qt = 'search'
      field.solr_parameters = {
        qf: '${qf_container}',
        pf: '${pf_container}'
      }
      field.clause_params = { edismax: field.solr_parameters.dup }
    end
    config.add_search_field 'title', label: 'Title' do |field|
      field.qt = 'search'
      field.solr_parameters = {
        qf: '${qf_title}',
        pf: '${pf_title}'
      }
      field.clause_params = { edismax: field.solr_parameters.dup }
    end
    config.add_search_field 'identifier', label: 'Identifier' do |field|
      field.qt = 'search'
      field.solr_parameters = {
        qf: '${qf_identifier}',
        pf: '${pf_identifier}'
      }
      field.clause_params = { edismax: field.solr_parameters.dup }
    end

    # These are the parameters passed through in search_state.params_for_search
    config.search_state_fields += %i[id group hierarchy_context original_document]
    config.search_state_fields << { original_parents: [] }

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    # DUL CUSTOMIZATION: relevance tiebreaker uses component order (sort_ii)
    # instead of title ABC.
    config.add_sort_field 'score desc, sort_isi asc, title_sort asc', label: 'relevance'
    config.add_sort_field 'date_sort asc', label: 'date (ascending)'
    config.add_sort_field 'date_sort desc', label: 'date (descending)'
    config.add_sort_field 'creator_sort asc', label: 'creator (A-Z)'
    config.add_sort_field 'creator_sort desc', label: 'creator (Z-A)'
    config.add_sort_field 'title_sort asc', label: 'title (A-Z)'
    config.add_sort_field 'title_sort desc', label: 'title (Z-A)'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Configuration for autocomplete suggestor
    config.autocomplete_enabled = true
    config.autocomplete_path = 'suggest'

    # ===========================
    # COLLECTION SHOW PAGE FIELDS
    # ===========================

    # Collection Show Page - Summary Section
    config.add_summary_field 'creators', field: 'creator_ssim', link_to_facet: true
    config.add_summary_field 'abstract', field: 'abstract_html_tesm', helper_method: :render_html_tags

    # DUL CUSTOMIZATION: singularize extent
    config.add_summary_field 'extent', field: 'extent_ssm', helper_method: :singularize_extent,
                                       separator_options: {
                                         words_connector: '<br/>',
                                         two_words_connector: '<br/>',
                                         last_word_connector: '<br/>'
                                       }
    # DUL CUSTOMIZATION: Add physdesc field as a summary instead of background
    config.add_summary_field 'physdesc', accessor: 'physdesc',
                                         separator_options: {
                                           words_connector: '<br/>',
                                           two_words_connector: '<br/>',
                                           last_word_connector: '<br/>'
                                         }

    config.add_summary_field 'language', accessor: 'languages',
                                         separator_options: {
                                           words_connector: '<br/>',
                                           two_words_connector: '<br/>',
                                           last_word_connector: '<br/>'
                                         }

    config.add_summary_field 'collection_unitid', accessor: true, label: 'Collection ID'

    # DUL CUSTOMIZATION: Add UA Record Group hierarchical facet.
    config.add_summary_field 'ua_record_group_ssim', label: 'University Archives Record Group',
                                                     link_to_facet: true, separator_options: {
                                                       words_connector: '<br/>',
                                                       two_words_connector: '<br/>',
                                                       last_word_connector: '<br/>'
                                                     }

    # DUL CUSTOMIZATION: Collection Show Page - Top Restrictions Teaser Section
    # We want to render a snippet of the Using... section at the top of the page,
    # and link to the full restrictions statement at the bottom. We'll create a
    # pseudo-field to hold this info, using the id field as a stand-in because it's always present.
    config.add_collection_restrictions_teaser_field 'using-these-materials-header',
                                                    field: 'id',
                                                    label: 'Using These Materials Links',
                                                    helper_method: :render_using_these_materials_header
    config.add_collection_restrictions_teaser_field 'accessrestrict',
                                                    field: 'accessrestrict_html_tesm',
                                                    label: 'Restrictions',
                                                    helper_method: :truncate_restrictions_teaser

    # DUL CUSTOM restrictions banner, used on both collection & component page
    config.add_restrictions_banner_field 'accessrestrict_collection_banner',
                                         field: 'accessrestrict_collection_banner_html_tesm',
                                         helper_method: :render_html_tags

    # Collection Show Page - Background Section
    config.add_background_field 'scopecontent', field: 'scopecontent_html_tesm', helper_method: :render_html_tags
    config.add_background_field 'bioghist', field: 'bioghist_html_tesm', helper_method: :render_html_tags
    config.add_background_field 'acqinfo', field: 'acqinfo_ssim', helper_method: :render_html_tags
    config.add_background_field 'appraisal', field: 'appraisal_html_tesm', helper_method: :render_html_tags
    config.add_background_field 'custodhist', field: 'custodhist_html_tesm', helper_method: :render_html_tags
    config.add_background_field 'processinfo', field: 'processinfo_html_tesm', helper_method: :render_html_tags
    config.add_background_field 'arrangement', field: 'arrangement_html_tesm', helper_method: :render_html_tags
    config.add_background_field 'accruals', field: 'accruals_html_tesm', helper_method: :render_html_tags
    # DUL CUSTOMIZATION: we removed phystech here as we treat it as a restriction
    # config.add_background_field 'phystech', field: 'phystech_html_tesm', helper_method: :render_html_tags
    config.add_background_field 'physloc', field: 'physloc_html_tesm', helper_method: :render_html_tags
    # DUL CUSTOMIZATION: we moved physdesc up into a summary field to be near extent
    # config.add_background_field 'physdesc', field: 'physdesc_tesim', helper_method: :render_html_tags
    config.add_background_field 'physfacet', field: 'physfacet_tesim', helper_method: :render_html_tags
    config.add_background_field 'dimensions', field: 'dimensions_tesim', helper_method: :render_html_tags
    config.add_background_field 'materialspec', field: 'materialspec_html_tesm', helper_method: :render_html_tags
    config.add_background_field 'fileplan', field: 'fileplan_html_tesm', helper_method: :render_html_tags
    config.add_background_field 'descrules', field: 'descrules_ssm', helper_method: :render_html_tags
    config.add_background_field 'note', field: 'note_html_tesm', helper_method: :render_html_tags
    # DUL CUSTOMIZATION: we moved odd from a 'related' field (core) to a 'background' field
    config.add_background_field 'odd', field: 'odd_html_tesm', helper_method: :render_html_tags

    # Collection Show Page - Related Section
    config.add_related_field 'relatedmaterial', field: 'relatedmaterial_html_tesm', helper_method: :render_html_tags
    config.add_related_field 'separatedmaterial', field: 'separatedmaterial_html_tesm', helper_method: :render_html_tags
    config.add_related_field 'otherfindaid', field: 'otherfindaid_html_tesm', helper_method: :render_html_tags
    config.add_related_field 'altformavail', field: 'altformavail_html_tesm', helper_method: :render_html_tags
    config.add_related_field 'originalsloc', field: 'originalsloc_html_tesm', helper_method: :render_html_tags

    # Collection Show Page - Indexed Terms Section
    config.add_indexed_terms_field 'access_subjects', field: 'access_subjects_ssim',
                                                      link_to_facet: true,
                                                      separator_options: {
                                                        words_connector: '<br/>',
                                                        two_words_connector: '<br/>',
                                                        last_word_connector: '<br/>'
                                                      }

    # DUL CUSTOMIZATION: add Format field
    config.add_indexed_terms_field 'format', field: 'genreform_ssim',
                                             link_to_facet: true,
                                             separator_options: {
                                               words_connector: '<br/>',
                                               two_words_connector: '<br/>',
                                               last_word_connector: '<br/>'
                                             }

    config.add_indexed_terms_field 'names_coll', field: 'names_coll_ssim',
                                                 separator_options: {
                                                   words_connector: '<br/>',
                                                   two_words_connector: '<br/>',
                                                   last_word_connector: '<br/>'
                                                 },
                                                 helper_method: :link_to_name_facet

    config.add_indexed_terms_field 'places', field: 'places_ssim',
                                             link_to_facet: true,
                                             separator_options: {
                                               words_connector: '<br/>',
                                               two_words_connector: '<br/>',
                                               last_word_connector: '<br/>'
                                             }

    # Collection Show Page - Indexes Section
    config.add_indexes_field 'indexes', field: 'indexes_html_tesm',
                                        label: 'Other Indexes to the Collection', helper_method: :render_html_tags

    # ==========================
    # COMPONENT SHOW PAGE FIELDS
    # ==========================

    # DUL CUSTOMIZATION:
    # Component-Level Restrictions Displayed in a Warning Box at the top of a component page
    config.add_component_restrictions_field 'accessrestrict',
                                            field: 'accessrestrict_html_tesm',
                                            label: 'Access Restrictions',
                                            helper_method: :render_html_tags
    # TODO: use :convert_rights_urls helper method
    config.add_component_restrictions_field 'userestrict',
                                            field: 'userestrict_html_tesm',
                                            label: 'Use Restrictions',
                                            helper_method: :render_html_tags
    config.add_component_restrictions_field 'phystech',
                                            field: 'phystech_html_tesm',
                                            label: 'Physical & Technical Requirements',
                                            helper_method: :render_html_tags

    # DUL CUSTOMIZATION: we want to render a simple link in this section to the full
    # restrictions statement at the bottom. We'll create a pseudo-field to hold this
    # link, using the id field as a stand-in because it's always present.
    config.add_component_restrictions_field 'view-more-restrictions',
                                            field: 'id',
                                            label: '',
                                            helper_method: :link_to_all_restrictions,
                                            if: lambda { |_context, _field_config, document|
                                              document.restricted_component?
                                            }

    # Component Show Page - Metadata Section

    config.add_component_field 'containers', accessor: 'containers', separator_options: {
      words_connector: ', ',
      two_words_connector: ', ',
      last_word_connector: ', '
    }, if: lambda { |_context, _field_config, document|
      document.containers.present?
    }
    config.add_component_field 'creators', field: 'creator_ssim', link_to_facet: true
    config.add_component_field 'abstract', field: 'abstract_html_tesm', helper_method: :render_html_tags

    # DUL CUSTOMIZATION: singularize extent
    config.add_component_field 'extent', field: 'extent_ssm', helper_method: :singularize_extent, separator_options: {
      words_connector: '<br/>',
      two_words_connector: '<br/>',
      last_word_connector: '<br/>'
    }

    config.add_component_field 'physdesc', field: 'physdesc_tesim', helper_method: :render_html_tags,
                                           separator_options: {
                                             words_connector: '<br/>',
                                             two_words_connector: '<br/>',
                                             last_word_connector: '<br/>'
                                           }

    config.add_component_field 'scopecontent', field: 'scopecontent_html_tesm', helper_method: :render_html_tags

    config.add_component_field 'language', accessor: 'languages',
                                           separator_options: {
                                             words_connector: '<br/>',
                                             two_words_connector: '<br/>',
                                             last_word_connector: '<br/>'
                                           }
    config.add_component_field 'acqinfo', field: 'acqinfo_ssim', helper_method: :render_html_tags
    config.add_component_field 'bioghist', field: 'bioghist_tesim', helper_method: :render_html_tags
    config.add_component_field 'appraisal', field: 'appraisal_html_tesm', helper_method: :render_html_tags
    config.add_component_field 'custodhist', field: 'custodhist_html_tesm', helper_method: :render_html_tags
    config.add_component_field 'processinfo', field: 'processinfo_html_tesm', helper_method: :render_html_tags
    config.add_component_field 'arrangement', field: 'arrangement_html_tesm', helper_method: :render_html_tags
    config.add_component_field 'accruals', field: 'accruals_html_tesm', helper_method: :render_html_tags
    # DUL CUSTOMIZATION: we removed phystech here as we treat it as a restriction
    # config.add_component_field 'phystech', field: 'phystech_html_tesm', helper_method: :render_html_tags
    config.add_component_field 'materialspec', field: 'materialspec_html_tesm', helper_method: :render_html_tags
    config.add_component_field 'physloc', field: 'physloc_html_tesm', helper_method: :render_html_tags
    # DUL CUSTOMIZATION: we moved physdesc up sequentially to be near extent, and used br separators
    # config.add_component_field 'physdesc', field: 'physdesc_tesim', helper_method: :render_html_tags
    config.add_component_field 'physfacet', field: 'physfacet_tesim', helper_method: :render_html_tags
    config.add_component_field 'dimensions', field: 'dimensions_tesim', helper_method: :render_html_tags
    config.add_component_field 'fileplan', field: 'fileplan_html_tesm', helper_method: :render_html_tags
    config.add_component_field 'altformavail', field: 'altformavail_html_tesm', helper_method: :render_html_tags
    config.add_component_field 'otherfindaid', field: 'otherfindaid_html_tesm', helper_method: :render_html_tags
    config.add_component_field 'odd', field: 'odd_html_tesm', helper_method: :render_html_tags
    config.add_component_field 'relatedmaterial', field: 'relatedmaterial_html_tesm', helper_method: :render_html_tags
    config.add_component_field 'separatedmaterial', field: 'separatedmaterial_html_tesm',
                                                    helper_method: :render_html_tags
    config.add_component_field 'originalsloc', field: 'originalsloc_html_tesm', helper_method: :render_html_tags
    config.add_component_field 'note', field: 'note_html_tesm', helper_method: :render_html_tags

    # Component Show Page - Indexed Terms Section
    config.add_component_indexed_terms_field 'access_subjects',
                                             field: 'access_subjects_ssim',
                                             link_to_facet: true,
                                             separator_options: {
                                               words_connector: '<br/>',
                                               two_words_connector: '<br/>',
                                               last_word_connector: '<br/>'
                                             }

    # DUL CUSTOMIZATION: add Format field
    config.add_component_indexed_terms_field 'format',
                                             field: 'genreform_ssim',
                                             link_to_facet: true,
                                             separator_options: {
                                               words_connector: '<br/>',
                                               two_words_connector: '<br/>',
                                               last_word_connector: '<br/>'
                                             }

    config.add_component_indexed_terms_field 'names', field: 'names_ssim', separator_options: {
      words_connector: '<br/>',
      two_words_connector: '<br/>',
      last_word_connector: '<br/>'
    }, helper_method: :link_to_name_facet

    config.add_component_indexed_terms_field 'places', field: 'places_ssim', link_to_facet: true, separator_options: {
      words_connector: '<br/>',
      two_words_connector: '<br/>',
      last_word_connector: '<br/>'
    }

    # Component Show Page - Indexes Section
    config.add_component_indexes_field 'indexes', field: 'indexes_tesim', label: 'Other Indexes',
                                                  helper_method: :render_html_tags

    # =================
    # ACCESS TAB FIELDS
    # =================

    # Collection Show Page Access Tab - Terms and Conditions Section
    config.add_terms_field 'using-these-materials-header',
                           field: 'id',
                           label: 'Using These Materials Links',
                           helper_method: :render_using_these_materials_header
    config.add_terms_field 'restrictions', field: 'accessrestrict_html_tesm', helper_method: :render_html_tags
    config.add_terms_field 'terms', field: 'userestrict_html_tesm', helper_method: :render_html_tags

    # Component Show Page Access Tab - Terms and Condition Section
    # DUL CUSTOMIZATION: we removed the component-level restrictions from this section in favor of
    # the warning box at the top of the component page.
    config.add_component_terms_field 'using-these-materials-header',
                                     field: 'id',
                                     label: 'Using These Materials Links',
                                     helper_method: :render_using_these_materials_header
    config.add_component_terms_field 'parent_restrictions', field: 'parent_access_restrict_tesm',
                                                            helper_method: :render_html_tags
    config.add_component_terms_field 'parent_terms', field: 'parent_access_terms_tesm', helper_method: :render_html_tags

    config.add_in_person_field 'before_you_visit', values: lambda { |_, document, _|
                                                             document.repository_config&.visit_note
                                                           }, helper_method: :render_html_tags

    # Collection and Component Show Page Access Tab - How to Cite Section
    config.add_cite_field 'prefercite', field: 'prefercite_html_tesm', helper_method: :render_html_tags

    # DUL CUSTOMIZATION: permalink field
    config.add_cite_field 'permalink_ssi', label: 'Permalink', helper_method: :render_links

    # Group header values
    config.add_group_header_field 'abstract_or_scope', accessor: true, truncate: true, helper_method: :render_html_tags

    # DUL CUSTOMIZATION: Fields to send in emails (esp. from bookmarks page)
    config.add_email_field 'normalized_title', accessor: true, label: 'Title'
    config.add_email_field 'short_description', accessor: true, label: 'Description',
                                                if: lambda { |_context, _field_config, document|
                                                      document.short_description.present?
                                                    }
    config.add_email_field 'ancestor_context', accessor: true, label: 'In',
                                               if: lambda { |_context, _field_config, document|
                                                     document.ancestor_context.present?
                                                   }
    config.add_email_field 'extent', accessor: true, label: 'Extent',
                                     if: lambda { |_context, _field_config, document|
                                           document.extent.present?
                                         }
    config.add_email_field 'physdesc', accessor: true, label: 'Physical Description',
                                       if: lambda { |_context, _field_config, document|
                                             document.physdesc.present?
                                           }
    config.add_email_field 'containers', accessor: true, label: 'Containers',
                                         if: lambda { |_context, _field_config, document|
                                               document.containers.present?
                                             }
  end
  # rubocop:enable Metrics/BlockLength
end
# rubocop:enable Metrics/ClassLength
