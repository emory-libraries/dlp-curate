# frozen_string_literal: true
# Bulkrax v8.2.3 override: create our own export_source rule for object_ids

module Bulkrax
  class Exporter < ApplicationRecord
    include Bulkrax::ImporterExporterBehavior
    include Bulkrax::StatusInfo

    serialize :parser_fields, JSON
    serialize :field_mapping, JSON

    belongs_to :user
    has_many :exporter_runs, dependent: :destroy
    has_many :entries, as: :importerexporter, dependent: :destroy

    validates :name, presence: true
    validates :parser_klass, presence: true

    delegate :write, :create_from_collection, :create_from_object_ids, :create_from_importer, :create_from_worktype, :create_from_all, to: :parser

    def export
      current_run && setup_export_path
      send("create_from_#{export_from}")
    rescue StandardError => e
      set_status_info(e)
    end

    def remove_and_rerun
      parser_fields['remove_and_rerun']
    end

    # #export_source accessors
    # Used in form to prevent it from getting confused as to which value to populate #export_source with.
    # Also, used to display the correct selected value when rendering edit form.
    def export_source_importer
      export_source if export_from == 'importer'
    end

    def export_source_collection
      export_source if export_from == 'collection'
    end

    def export_source_worktype
      export_source if export_from == 'worktype'
    end

    # Emory Addition: create our own export_source rule for object_ids
    def export_source_object_ids
      export_source if export_from == 'object_ids'
    end

    def date_filter
      start_date.present? || finish_date.present?
    end

    def include_thumbnails?
      include_thumbnails
    end

    def generated_metadata?
      generated_metadata
    end

    def work_visibility_list
      [
        ['Any', ''],
        [I18n.t('hyrax.visibility.open.text'), Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC],
        [I18n.t('hyrax.visibility.restricted.text'), Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE],
        [I18n.t('hyrax.visibility.authenticated.text', institution: I18n.t('hyrax.institution_name')), Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED]
      ]
    end

    def workflow_status_list
      Sipity::WorkflowState.all.map { |s| [s.name&.titleize, s.name] }.uniq if defined?(::Hyrax)
    end

    # If field_mapping is empty, setup a default based on the export_properties
    def mapping
      @mapping ||= field_mapping ||
                   ActiveSupport::HashWithIndifferentAccess.new(
                     export_properties.map do |m|
                       Bulkrax.default_field_mapping.call(m)
                     end.inject(:merge)
                   ) ||
                   [{}]
    end

    def export_from_list
      if defined?(::Hyrax)
        [
          [I18n.t('bulkrax.exporter.labels.importer'), 'importer'],
          [I18n.t('bulkrax.exporter.labels.collection'), 'collection'],
          ['Object IDs', 'object_ids'],
          [I18n.t('bulkrax.exporter.labels.worktype'), 'worktype'],
          [I18n.t('bulkrax.exporter.labels.all'), 'all']
        ]
      else
        [
          [I18n.t('bulkrax.exporter.labels.importer'), 'importer'],
          [I18n.t('bulkrax.exporter.labels.collection'), 'collection'],
          ['Object IDs', 'object_ids'],
          [I18n.t('bulkrax.exporter.labels.all'), 'all']
        ]
      end
    end

    def export_type_list
      [
        [I18n.t('bulkrax.exporter.labels.metadata'), 'metadata'],
        [I18n.t('bulkrax.exporter.labels.full'), 'full']
      ]
    end

    def importers_list
      Importer.all.map { |i| [i.name, i.id] }
    end

    def current_run(skip_counts: false)
      @current_run ||= exporter_runs.create! if skip_counts
      return @current_run if @current_run

      total = limit || parser.total
      @current_run = exporter_runs.create!(total_work_entries: total, enqueued_records: total)
    end

    def last_run
      @last_run ||= exporter_runs.last
    end

    def setup_export_path
      FileUtils.mkdir_p(exporter_export_path) unless File.exist?(exporter_export_path)
    end

    def exporter_export_path
      @exporter_export_path ||= File.join(parser.base_path('export'), id.to_s, exporter_runs.last.id.to_s)
    end

    def exporter_export_zip_path
      @exporter_export_zip_path ||= File.join(parser.base_path('export'), "export_#{id}_#{exporter_runs.last.id}")
    rescue
      @exporter_export_zip_path ||= File.join(parser.base_path('export'), "export_#{id}_0")
    end

    def exporter_export_zip_files
      @exporter_export_zip_files ||= Dir["#{exporter_export_zip_path}/**"].map { |zip| Array(zip.split('/').last) }
    end

    def export_properties
      # TODO: Does this work for Valkyrie?
      Bulkrax.object_factory.export_properties
    end

    def metadata_only?
      export_type == 'metadata'
    end

    def sort_zip_files(zip_files)
      zip_files.sort_by do |item|
        number = item.split('_').last.match(/\d+/)&.[](0) || 0.to_s
        sort_number = number.rjust(4, "0")

        sort_number
      end
    end
  end
end
