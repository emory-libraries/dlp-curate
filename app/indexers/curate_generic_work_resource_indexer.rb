# frozen_string_literal: true

# Valkyrie indexer for CurateGenericWorkResource.
# Mirrors the custom Solr fields from the AF CurateGenericWorkIndexer.
# rubocop:disable Metrics/ClassLength
class CurateGenericWorkResourceIndexer < Hyrax::Indexers::PcdmObjectIndexer(CurateGenericWorkResource)
  include Hyrax::Indexer(:emory_basic_metadata)
  include Hyrax::Indexer(:curate_generic_work_resource)

  def to_solr
    super.tap do |solr_doc|
      add_sort_and_date_fields(solr_doc)
      add_relationship_fields(solr_doc)
      add_display_fields(solr_doc)
      add_human_readable_data_to(solr_doc)
      add_full_text_data_to(solr_doc)
    end
  end

  private

    def add_sort_and_date_fields(solr_doc)
      solr_doc['year_created_isim'] = year_created
      solr_doc['year_issued_isim'] = year_issued
      solr_doc['year_for_lux_isim'] = year_for_lux
      solr_doc['title_ssort'] = sort_title
      solr_doc['creator_ssort'] = resource.creator.first
      solr_doc['year_for_lux_ssi'] = sort_year
    end

    def add_relationship_fields(solr_doc)
      solr_doc['child_works_for_lux_tesim'] = child_works_for_lux
      solr_doc['parent_work_for_lux_tesim'] = parent_work_for_lux
      solr_doc['source_collection_title_ssim'] = source_collection_title
    end

    def add_display_fields(solr_doc)
      solr_doc['manifest_cache_key_tesim'] = manifest_cache_key
      solr_doc['representative_file_type_ssi'] = representative_file_type
      solr_doc['visibility_group_ssi'] = visibility_group_for_lux
      solr_doc['human_readable_visibility_ssi'] = human_readable_visibility
    end

    def year_created
      integer_years = YearParser.integer_years(resource.date_created)
      return nil if integer_years.blank?
      integer_years
    end

    def year_issued
      integer_years = YearParser.integer_years(resource.date_issued)
      return nil if integer_years.blank?
      integer_years
    end

    def year_for_lux
      years = [year_created, year_issued].flatten.compact.uniq.sort
      return nil if years.empty?
      years
    end

    def sort_title
      return unless resource.title.first
      resource.title.first.gsub(/^(an?|the)\s/i, '')
    end

    def sort_year
      year_for_lux.nil? ? nil : year_for_lux.first
    end

    def child_works_for_lux
      children = sorted_child_works
      return nil if children.empty?
      children.map { |c| format_child_work_for_lux(c) }
    rescue StandardError
      nil
    end

    def sorted_child_works
      return [] if resource.member_ids.blank?
      children = resource.member_ids.filter_map do |mid|
        child = Hyrax.query_service.find_by(id: mid)
        child if child.is_a?(Hyrax::Work)
      rescue Valkyrie::Persistence::ObjectNotFoundError
        nil
      end
      children.sort_by { |c| c.title.first.to_s }
    end

    def format_child_work_for_lux(child)
      solr_doc = Hyrax::SolrService.query("id:#{child.id}", rows: 1).first
      thumbnail_path = solr_doc&.dig("thumbnail_path_ss")
      "#{child.id}, #{thumbnail_path}, #{child.title.first}"
    end

    def parent_work_for_lux
      parents = Hyrax.custom_queries.find_parent_works(resource:)
      parent = parents.first
      return nil if parent.nil?
      ["#{parent.id}, #{parent.title.first}"]
    rescue StandardError
      nil
    end

    def visibility_group_for_lux
      case resource.visibility
      when "open", "low_res"
        "Public"
      when "emory_low", "authenticated"
        "Log In Required"
      when "rose_high"
        "Reading Room Only"
      end
    end

    def human_readable_visibility
      case resource.visibility
      when "open" then "Public"
      when "low_res" then "Public Low View"
      when "emory_low" then "Emory Low Download"
      when "authenticated" then "Emory High Download"
      when "rose_high" then "Rose High View"
      when "restricted" then "Private"
      end
    end

    def source_collection_title
      return if resource.source_collection_id.blank?
      source = Hyrax.query_service.find_by(id: resource.source_collection_id)
      source&.title
    rescue Valkyrie::Persistence::ObjectNotFoundError
      nil
    end

    def manifest_cache_key
      Digest::MD5.hexdigest(manifest_cache_components.join)
    rescue StandardError
      nil
    end

    def manifest_cache_components
      file_sets = Hyrax.custom_queries.find_child_file_sets(resource:)
      [
        resource.title.first.to_s,
        file_sets.count.to_s,
        Array(resource.holding_repository).first.to_s,
        Array(resource.rights_statement).first.to_s,
        resource.visibility.to_s,
        file_set_visibilities(file_sets),
        rendering_ids_string
      ]
    end

    def file_set_visibilities(file_sets)
      file_sets.map { |fs| fs.respond_to?(:visibility) ? fs.visibility : "" }.join
    end

    def rendering_ids_string
      resource.respond_to?(:rendering_ids) ? Array(resource.rendering_ids).sort.to_s : ""
    end

    def representative_file_type
      rep_id = resource.representative_id
      return if rep_id.blank?
      representative_doc = SolrDocument.find(rep_id.to_s)
      representative_doc&.pdf? ? 'pdf' : nil
    rescue Blacklight::Exceptions::RecordNotFound
      nil
    end

    def human_readable_content_type
      return if resource.content_type.blank?
      FormatLabelService.instance.label(uri: resource.content_type)
    rescue StandardError
      nil
    end

    def human_readable_rights_statement
      statements = Array(resource.rights_statement)
      return [] if statements.empty?
      RightsStatementLabelService.instance.label(uri: statements.first)
    rescue StandardError
      []
    end

    def human_readable_re_use_license
      return if resource.re_use_license.blank?
      LicensesLabelService.instance.label(uri: resource.re_use_license)
    rescue StandardError
      nil
    end

    def human_readable_date_created
      return if resource.date_created.blank?
      DateService.instance.human_readable_date(resource.date_created)
    rescue StandardError
      nil
    end

    def human_readable_date_issued
      return if resource.date_issued.blank?
      DateService.instance.human_readable_date(resource.date_issued)
    rescue StandardError
      nil
    end

    def human_readable_data_collection_dates
      dates = Array(resource.data_collection_dates)
      return [] if dates.empty?
      dates.map { |date| DateService.instance.human_readable_date(date) }
    rescue StandardError
      []
    end

    def human_readable_conference_dates
      return if resource.conference_dates.blank?
      DateService.instance.human_readable_date(resource.conference_dates)
    rescue StandardError
      nil
    end

    def human_readable_copyright_date
      return if resource.copyright_date.blank?
      DateService.instance.human_readable_date(resource.copyright_date)
    rescue StandardError
      nil
    end

    def add_full_text_data_to(solr_doc)
      full_text = full_text_data
      return if full_text.blank?
      solr_doc['all_text_timv'] = full_text
      solr_doc['all_text_tsimv'] = full_text
    end

    def full_text_data
      label = "Full Text Data - #{resource.id}"
      results = Hyrax::SolrService.query("label_tesim:\"#{label}\"", fl: "id", sort: "date_uploaded_dtsi desc", rows: 1)
      return nil if results.blank?
      file_set = Hyrax.query_service.find_by(id: results.first["id"])
      Hyrax.config.file_set_file_service.new(file_set:).primary_file&.content
    rescue StandardError
      nil
    end

    def add_human_readable_data_to(solr_doc)
      solr_doc['human_readable_content_type_ssim'] = [human_readable_content_type]
      solr_doc['human_readable_rights_statement_ssim'] = [human_readable_rights_statement]
      solr_doc['human_readable_re_use_license_ssim'] = [human_readable_re_use_license]
      solr_doc['human_readable_date_created_tesim'] = [human_readable_date_created]
      solr_doc['human_readable_date_issued_tesim'] = [human_readable_date_issued]
      solr_doc['human_readable_data_collection_dates_tesim'] = human_readable_data_collection_dates
      solr_doc['human_readable_conference_dates_tesim'] = [human_readable_conference_dates]
      solr_doc['human_readable_copyright_date_tesim'] = [human_readable_copyright_date]
    end
end
# rubocop:enable Metrics/ClassLength
