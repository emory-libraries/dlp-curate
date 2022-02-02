# frozen_string_literal: true
# [Hyrax-overwrite-v3.0.2]
module Hyrax
  class CollectionPresenter
    include ModelProxy
    include PresentsAttributes
    include ActionView::Helpers::NumberHelper
    include ActionView::Helpers::TagHelper
    include CuratePurl
    attr_accessor :solr_document, :current_ability, :request
    attr_reader :subcollection_count
    attr_accessor :parent_collections # This is expected to be a Blacklight::Solr::Response with all of the parent collections
    attr_writer :collection_type

    class_attribute :create_work_presenter_class
    self.create_work_presenter_class = Hyrax::SelectTypeListPresenter

    # @param [SolrDocument] solr_document
    # @param [Ability] current_ability
    # @param [ActionDispatch::Request] request the http request context
    def initialize(solr_document, current_ability, request = nil)
      @solr_document = solr_document
      @current_ability = current_ability
      @request = request
      @subcollection_count = 0
    end

    # CurationConcern methods
    delegate :stringify_keys, :human_readable_type, :collection?, :representative_id,
             :to_s, to: :solr_document

    delegate(*Hyrax::CollectionType.settings_attributes, to: :collection_type, prefix: :collection_type_is)

    def collection_type
      @collection_type ||= Hyrax::CollectionType.find_by_gid!(collection_type_gid)
    end

    CurateGenericWorkAttributes.instance.attributes.each do |key|
      delegate key.to_sym, to: :solr_document
    end
    # Metadata Methods
    delegate :title, :description, :creator, :contributors, :subject, :publisher,
             :keyword, :language, :embargo_release_date, :lease_expiration_date,
             :license, :date_created, :resource_type, :based_near, :related_url,
             :identifier, :thumbnail_path, :title_or_label, :collection_type_gid,
             :create_date, :modified_date, :visibility, :edit_groups, :edit_people,
             :holding_repository, :administrative_unit, :contributors, :abstract,
             :primary_language, :finding_aid_link, :institution, :local_call_number,
             :keywords, :subject_topics, :subject_names, :subject_geo, :subject_time_periods,
             :notes, :rights_documentation, :sensitive_material, :internal_rights_note,
             :contact_information, :staff_notes, :system_of_record_ID, :emory_ark,
             :primary_repository_ID,
             to: :solr_document

    # Terms is the list of fields displayed by
    # app/views/collections/_show_descriptions.html.erb
    def self.terms
      [
        :holding_repository,
        :administrative_unit,
        :contributors,
        :abstract,
        :primary_language,
        :finding_aid_link,
        :institution,
        :local_call_number,
        :keywords,
        :subject_topics,
        :subject_names,
        :subject_geo,
        :subject_time_periods,
        :notes,
        :rights_documentation,
        :sensitive_material,
        :internal_rights_note,
        :contact_information,
        :staff_notes,
        :system_of_record_ID,
        :emory_ark,
        :primary_repository_ID
      ]
    end

    def terms_with_values
      self.class.terms.select { |t| self[t].present? }
    end

    ##
    # @param [Symbol] key
    # @return [Object]
    def [](key)
      case key
      when :size
        size
      when :total_items
        total_items
      else
        solr_document.send key
      end
    end

    # @deprecated to be removed in 4.0.0; this feature was replaced with a
    #   hard-coded null implementation
    # @return [String] 'unknown'
    def size
      Deprecation.warn('#size has been deprecated for removal in Hyrax 4.0.0; ' \
                       'The implementation of the indexed Collection size ' \
                       'feature is extremely inefficient, so it has been removed. ' \
                       'This method now returns a hard-coded `"unknown"` for ' \
                       'compatibility.')
      'unknown'
    end

    def total_items
      Hyrax::SolrService.new.count("member_of_collection_ids_ssim:#{id}")
    end

    # Product Owner preferred that the count not be restricted by user's ability to
    # view the works when seeing the Deposited Items counts on the Collection Index
    # page.
    def total_viewable_items
      total_items
    end

    def total_viewable_works
      ActiveFedora::Base.where("member_of_collection_ids_ssim:#{id} AND generic_type_sim:Work").accessible_by(current_ability).count
    end

    def total_viewable_collections
      ActiveFedora::Base.where("member_of_collection_ids_ssim:#{id} AND generic_type_sim:Collection").accessible_by(current_ability).count
    end

    def collection_type_badge
      tag.span(collection_type.title, class: "label", style: "background-color: " + collection_type.badge_color + ";")
    end

    # The total number of parents that this collection belongs to, visible or not.
    def total_parent_collections
      parent_collections.nil? ? 0 : parent_collections.response['numFound']
    end

    # The number of parent collections shown on the current page. This will differ from total_parent_collections
    # due to pagination.
    def parent_collection_count
      parent_collections.nil? ? 0 : parent_collections.documents.size
    end

    def user_can_nest_collection?
      current_ability.can?(:deposit, solr_document)
    end

    def user_can_create_new_nest_collection?
      current_ability.can?(:create_collection_of_type, collection_type)
    end

    def show_path
      Hyrax::Engine.routes.url_helpers.dashboard_collection_path(id, locale: I18n.locale)
    end

    def banner_file
      banner = CollectionBrandingInfo.find_by(collection_id: id, role: "banner")
      "/" + banner.local_path.split("/")[-4..-1].join("/") if banner
    end

    def logo_record
      CollectionBrandingInfo.where(collection_id: id, role: "logo")
                            .select(:local_path, :alt_text, :target_url).map do |logo|
        {
          alttext:       logo.alt_text,
          file:          File.split(logo.local_path).last,
          file_location: "/#{logo.local_path.split('/')[-4..-1].join('/')}",
          linkurl:       logo.target_url
        }
      end
    end

    # A presenter for selecting a work type to create
    # this is needed here because the selector is in the header on every page
    def create_work_presenter
      @create_work_presenter ||= create_work_presenter_class.new(current_ability.current_user)
    end

    def create_many_work_types?
      create_work_presenter.many?
    end

    def draw_select_work_modal?
      create_many_work_types?
    end

    def first_work_type
      create_work_presenter.first_model
    end

    def available_parent_collections(scope:)
      return @available_parents if @available_parents.present?
      collection = ::Collection.find(id)
      colls = Hyrax::Collections::NestedCollectionQueryService.available_parent_collections(child: collection, scope: scope, limit_to_id: nil)
      @available_parents = colls.map do |col|
        { "id" => col.id, "title_first" => col.title.first }
      end
      @available_parents.to_json
    end

    def subcollection_count=(total)
      @subcollection_count = total unless total.nil?
    end

    # For the Managed Collections tab, determine the label to use for the level of access the user has for this admin set.
    # Checks from most permissive to most restrictive.
    # @return String the access label (e.g. Manage, Deposit, View)
    def managed_access
      return I18n.t('hyrax.dashboard.my.collection_list.managed_access.manage') if current_ability.can?(:edit, solr_document)
      return I18n.t('hyrax.dashboard.my.collection_list.managed_access.deposit') if current_ability.can?(:deposit, solr_document)
      return I18n.t('hyrax.dashboard.my.collection_list.managed_access.view') if current_ability.can?(:read, solr_document)
      ''
    end

    # Determine if the user can perform batch operations on this collection.  Currently, the only
    # batch operation allowed is deleting, so this is equivalent to checking if the user can delete
    # the collection determined by criteria...
    # * user must be able to edit the collection to be able to delete it
    # * the collection does not have to be empty
    # @return Boolean true if the user can perform batch actions; otherwise, false
    def allow_batch?
      return true if current_ability.can?(:edit, solr_document)
      false
    end

    # Change below was necessary to institute Source/Deposit Collection structure.
    # For more information, read the SOURCE_DEPOSIT_CHANGES_README.md in dlp-curate's root folder.
    def deposit_collection?
      source_coll_id.present? && source_coll_id[0] != id
    end

    def source_collection_object
      { title: solr_document['source_collection_title_for_collections_ssim'][0], id: source_coll_id[0] }
    end

    def source_coll_id
      solr_document['source_collection_id_tesim']
    end

    def deposit_collection_ids
      solr_document['deposit_collection_ids_tesim']
    end

    def deposit_collections
      deposit_collection_ids&.map { |id| { id: id, title: Collection.find(id).title.first } }
    end
  end
end
