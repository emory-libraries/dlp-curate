# frozen_string_literal: true

class CatalogController < ApplicationController
  include Hydra::Catalog
  include Hydra::Controller::ControllerBehavior

  # This filter applies the hydra access controls
  before_action :enforce_show_permissions, only: :show

  def self.uploaded_field
    solr_name('system_create', :stored_sortable, type: :date)
  end

  def self.modified_field
    solr_name('system_modified', :stored_sortable, type: :date)
  end

  # CatalogController-scope behavior and configuration for BlacklightIiifSearch
  include BlacklightIiifSearch::Controller
  skip_before_action :authenticate_user!, only: :iiif_search

  configure_blacklight do |config|
    # configuration for Blacklight IIIF Content Search
    config.iiif_search = {
      full_text_field:       'transcript_text_tesi', # FileSet field
      object_relation_field: 'is_page_of_ssi', # FileSet field
      supported_params:      %w[q page],
      autocomplete_handler:  'iiif_suggest',
      suggester_name:        'iiifSuggester'
    }

    config.view.gallery(document_component: Blacklight::Gallery::DocumentComponent)
    config.view.masonry(document_component: Blacklight::Gallery::DocumentComponent)
    config.view.slideshow(document_component: Blacklight::Gallery::SlideshowComponent)

    config.show.tile_source_field = :content_metadata_image_iiif_info_ssm
    config.show.partials.insert(1, :openseadragon)
    config.search_builder_class = Hyrax::CatalogSearchBuilder

    # Because too many times on Samvera tech people raise a problem regarding a failed query to SOLR.
    # Often, it's because they inadvertently exceeded the character limit of a GET request.
    config.http_method = Hyrax.config.solr_default_method

    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    # NOTE: transcript_text_tesi is needed here because the `iiif_search` path utilizes the default `search` qt to
    #   match terms in Full-Text search-enabled FileSets.
    config.default_solr_params = {
      qt:   "search",
      rows: 10,
      qf:   "title_tesim description_tesim creator_tesim keyword_tesim transcript_text_tesi"
    }

    # solr field configuration for document/show views
    config.index.title_field = solr_name("title", :stored_searchable)
    config.index.display_type_field = solr_name("has_model", :symbol)
    config.index.thumbnail_field = 'thumbnail_path_ss'

    config.add_results_document_tool(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    config.add_results_collection_tool(:view_type_group)
    config.add_show_tools_partial(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
    config.add_show_tools_partial(:email, callback: :email_action, validator: :validate_email_params)
    config.add_show_tools_partial(:sms, if: :render_sms_action?, callback: :sms_action, validator: :validate_sms_params)
    config.add_show_tools_partial(:citation)
    config.add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
    config.add_nav_action(:search_history, partial: 'blacklight/nav/search_history')

    # solr fields that will be treated as facets by the blacklight application
    # The ordering of the field names is the order of the display
    config.add_facet_field 'holding_repository_sim', limit: 5, label: 'Library'
    # Change below was necessary to institute Source/Deposit Collection structure.
    # For more information, read the SOURCE_DEPOSIT_CHANGES_README.md in dlp-curate's root folder.
    config.add_facet_field 'source_collection_title_ssim', limit: 10, label: 'Collection'
    config.add_facet_field 'creator_sim', limit: 10, label: 'Creator'
    config.add_facet_field 'human_readable_content_type_ssim', limit: 10, label: 'Format'
    config.add_facet_field 'content_genres_sim', limit: 10, label: 'Genre'
    config.add_facet_field 'primary_language_sim', limit: 5, label: 'Language'
    config.add_facet_field 'year_created_isim', label: 'Date'
    config.add_facet_field 'year_issued_isim', label: 'Publication Date'
    config.add_facet_field 'subject_topics_sim', limit: 10, label: 'Subject - Topics'
    config.add_facet_field 'subject_names_sim', limit: 10, label: 'Subject - Names'
    config.add_facet_field 'subject_geo_sim', limit: 10, label: 'Subject - Geographic'
    config.add_facet_field 'human_readable_rights_statement_ssim', label: 'Rights Status'
    config.add_facet_field 'visibility_group_ssi', label: 'Access'

    # The generic_type and depositor are not displayed on the facet list
    # They are used to give a label to the filters that comes from the user profile
    config.add_facet_field solr_name("generic_type", :facetable), if: false
    config.add_facet_field "depositor_ssim", label: "Depositor", if: false

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    # The ordering of the field names is the order of the display
    config.add_index_field solr_name("title", :stored_searchable), label: "Title", itemprop: 'name', if: false
    config.add_index_field solr_name("holding_repository", :stored_searchable), label: "Library", itemprop: 'holding_repository'
    config.add_index_field 'member_of_collections_ssim', label: "Collection", itemprop: 'member_of_collections'
    config.add_index_field solr_name("date_uploaded", :stored_sortable, type: :date), label: 'Date Uploaded', itemprop: 'datePublished', helper_method: :human_readable_date
    config.add_index_field solr_name("date_modified", :stored_sortable, type: :date), label: 'Date Modified', itemprop: 'dateModified', helper_method: :human_readable_date
    config.add_index_field 'human_readable_visibility_ssi', label: 'Visibility', itemprop: 'human_readable_visibility'
    config.add_index_field 'deduplication_key_tesim', label: 'Deduplication Key', itemprop: 'deduplication_key'
    config.add_index_field 'id', label: 'ID', itemprop: 'id'
    config.add_index_field 'all_text_tsimv', highlight: true, helper_method: :render_ocr_snippets

    # solr fields to be displayed in the show (single result) view
    # The ordering of the field names is the order of the display
    CurateGenericWorkAttributes.instance.attributes.each do |key|
      config.add_show_field solr_name(key, :stored_searchable)
    end

    config.add_show_field solr_name("identifier", :stored_searchable)

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
    #
    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.
    config.add_search_field('all_fields', label: 'All Fields') do |field|
      all_names = config.show_fields.values.map(&:field).join(" ")
      title_name = solr_name("title", :stored_searchable)
      field.solr_parameters = {
        qf: "#{all_names} file_format_tesim all_text_timv id",
        pf: title_name.to_s
      }
    end

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.
    # creator, title, description, publisher, date_created,
    # subject, language, resource_type, format, identifier, based_near,
    config.add_search_field('contributors') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      solr_name = solr_name("contributors", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('creator') do |field|
      solr_name = solr_name("creator", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('title') do |field|
      solr_name = solr_name("title", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('description') do |field|
      field.label = "Abstract or Summary"
      solr_name = solr_name("description", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('publisher') do |field|
      solr_name = solr_name("publisher", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('date_created') do |field|
      solr_name = solr_name("created", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('subject') do |field|
      solr_name = solr_name("subject", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('language') do |field|
      solr_name = solr_name("language", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('resource_type') do |field|
      solr_name = solr_name("resource_type", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('format') do |field|
      solr_name = solr_name("format", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('identifier') do |field|
      solr_name = solr_name("id", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('based_near') do |field|
      field.label = "Location"
      solr_name = solr_name("based_near_label", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('keyword') do |field|
      solr_name = solr_name("keyword", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('depositor') do |field|
      solr_name = solr_name("depositor", :symbol)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('rights_statement') do |field|
      solr_name = solr_name("rights_statement", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('license') do |field|
      solr_name = solr_name("license", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    # label is key, solr field is value
    config.add_sort_field "score desc, #{uploaded_field} desc", label: "relevance"
    config.add_sort_field "#{uploaded_field} desc", label: "date uploaded \u25BC"
    config.add_sort_field "#{uploaded_field} asc", label: "date uploaded \u25B2"
    config.add_sort_field "#{modified_field} desc", label: "date modified \u25BC"
    config.add_sort_field "#{modified_field} asc", label: "date modified \u25B2"

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  # disable the bookmark control from displaying in gallery view
  # Hyrax doesn't show any of the default controls on the list view, so
  # this method is not called in that context.
  def render_bookmarks_control?
    false
  end
end
