# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class FileSetCleanUpJob < Hyrax::ApplicationJob
  def perform(file_set_id = nil)
    CSV.open("config/emory/index_file_set_results.csv", "w") do |csv|
      if file_set_id.present?
        process_fileset(find_file_set(file_set_id), csv)
      else
        iterate_all_file_sets(csv)
      end
    end
  end

  private

    def find_file_set(id)
      if Hyrax.config.valkyrie_transition?
        Hyrax.query_service.find_by(id:)
      else
        ::FileSet.find(id)
      end
    end

    def iterate_all_file_sets(csv)
      if Hyrax.config.valkyrie_transition?
        file_set_docs = Hyrax::SolrService.query("has_model_ssim:FileSet", rows: 1_000_000, fl: "id")
        file_set_docs.each do |doc|
          fs = Hyrax.query_service.find_by(id: doc["id"])
          process_fileset(fs, csv)
        end
      else
        FileSet.all.each { |file_set| process_fileset(file_set, csv) }
      end
    end

    def process_fileset(file_set, csv)
      case file_set
      when Hyrax::Resource
        process_valkyrie_fileset(file_set, csv)
      else
        process_af_fileset(file_set, csv)
      end
    end

    def process_af_fileset(file_set, csv)
      if file_set.mime_type.nil?
        csv << [file_set.id, "Fileset not characterized", "Not fixed"]
      else
        solr_doc = SolrDocument.find(file_set.id)
        if solr_doc.mime_type.nil?
          reindex_af_file_set(file_set, csv)
        elsif solr_doc.thumbnail_path.to_s.start_with?("/assets/default-")
          regenerate_af_derivatives(file_set, csv)
        end
      end
    end

    def process_valkyrie_fileset(file_set, csv)
      fm = original_file_metadata(file_set)
      if fm.nil? || fm.mime_type.blank?
        csv << [file_set.id.to_s, "Fileset not characterized", "Not fixed"]
      else
        solr_doc = SolrDocument.find(file_set.id.to_s)
        if solr_doc.mime_type.nil?
          reindex_valkyrie_file_set(file_set, csv)
        elsif solr_doc.thumbnail_path.to_s.start_with?("/assets/default-")
          regenerate_valkyrie_derivatives(file_set, fm, csv)
        end
      end
    end

    def original_file_metadata(file_set)
      Hyrax.custom_queries
           .find_many_file_metadata_by_use(resource: file_set, use: Hyrax::FileMetadata::Use::ORIGINAL_FILE)
           .first
    end

    def reindex_af_file_set(file_set, csv)
      file_set.to_solr
      file_set.save!
      csv << [file_set.id, "Fileset not indexed", "Fixed"]
    end

    def reindex_valkyrie_file_set(file_set, csv)
      Hyrax.index_adapter.save(resource: file_set)
      csv << [file_set.id.to_s, "Fileset not indexed", "Fixed"]
    end

    def regenerate_af_derivatives(file_set, csv)
      preferred_file_symbol = file_set.preferred_file
      preferred_file_uri = file_set.send(preferred_file_symbol).uri.to_s
      asset_path = preferred_file_uri[preferred_file_uri.index(file_set.id.to_s)..-1]
      CreateDerivativesJob.perform_later(file_set, asset_path)
      csv << [file_set.id, "Thumbnail_path mismatch in solr_doc", "Queued"]
    end

    def regenerate_valkyrie_derivatives(file_set, file_metadata, csv)
      Hyrax.publisher.publish('file.characterized',
                              file_set:,
                              file_id:   file_metadata.id.to_s,
                              path_hint: file_metadata.file_identifier.to_s)
      csv << [file_set.id.to_s, "Thumbnail_path mismatch in solr_doc", "Queued"]
    end
end
# rubocop:enable Metrics/ClassLength
