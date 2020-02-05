# frozen_string_literal: true
class IndexFileSet
  class << self
    def process
      CSV.open("config/emory/index_file_set_results.csv", "w") do |csv|
        FileSet.all.each do |file_set|
          if file_set.mime_type.nil? # check if file_set is characterized
            csv << [file_set.id, "Fileset not characterized", "Not fixed"]
          else
            solr_doc = SolrDocument.find(file_set.id)
            if solr_doc.mime_type.nil? # when file_set is characterized but wasn't indexed properly
              reindex_file_set(file_set, csv)
            elsif solr_doc.thumbnail_path.to_s.start_with?("/assets/default-") # when file_set was characterized but thumbnail_path in solr doc is incorrect
              regenerate_derivatives(file_set, csv)
            end
          end
        end
      end
    end

    private

      def reindex_file_set(file_set, csv)
        file_set.to_solr
        file_set.save!
        csv << [file_set.id, "Fileset not indexed", "Fixed"]
      end

      def regenerate_derivatives(file_set, csv)
        preferred_file_symbol = file_set.preferred_file
        preferred_file_uri = file_set.send(preferred_file_symbol).uri.to_s
        asset_path = preferred_file_uri[preferred_file_uri.index(file_set.id.to_s)..-1]
        CreateDerivativesJob.perform_later(file_set, asset_path)
        csv << [file_set.id, "Thumbnail_path mismatch in solr_doc", "Queued"]
      end
  end
end
