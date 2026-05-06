# frozen_string_literal: true
require 'aws-sdk-s3'

class CheckBinariesJob < Hyrax::ApplicationJob
  def perform(bucket, file_set_id = nil)
    CSV.open("config/emory/check_binaries_results.csv", "w") do |csv|
      @s3 = Aws::S3::Resource.new(region: 'us-east-1')
      @bucket = @s3.bucket(bucket)

      if file_set_id.present?
        fs = find_file_set(file_set_id)
        check_binary(fs, csv)
      else
        check_all_file_sets(csv)
      end
    end
  end

  private

    def find_file_set(id)
      if Hyrax.config.valkyrie_transition?
        Hyrax.query_service.find_by(id:)
      else
        FileSet.find(id)
      end
    end

    def check_binary(file_set, csv)
      case file_set
      when Hyrax::Resource
        check_valkyrie_binary(file_set, csv)
      else
        check_af_binary(file_set, csv)
      end
    end

    def check_af_binary(file_set, csv)
      file_set.files.each do |file|
        next if file.digest.empty? || check_existence_in_s3(file.digest.first.to_s)
        csv << [file_set.member_of_work_ids.join('|'), file_set.id, file&.id, @sha1]
      end
    end

    def check_valkyrie_binary(file_set, csv)
      file_metadatas = Hyrax.custom_queries.find_files(file_set:)
      file_metadatas.each do |fm|
        checksums = Array(fm.original_checksum)
        sha1_entry = checksums.find { |c| c.to_s.start_with?('urn:sha1:') }
        next if sha1_entry.blank? || check_existence_in_s3(sha1_entry.to_s)
        parent_ids = Array(file_set.member_of_collection_ids).map(&:to_s)
        csv << [parent_ids.join('|'), file_set.id.to_s, fm.id.to_s, @sha1]
      end
    end

    def check_all_file_sets(csv)
      if Hyrax.config.valkyrie_transition?
        check_all_valkyrie(csv)
      else
        FileSet.all.each do |file_set|
          check_binary(file_set, csv) unless file_set.files.empty?
        end
      end
    end

    def check_all_valkyrie(csv)
      file_set_docs = Hyrax::SolrService.query("has_model_ssim:FileSet", rows: 1_000_000, fl: "id")
      file_set_docs.each do |doc|
        fs = Hyrax.query_service.find_by(id: doc["id"])
        check_valkyrie_binary(fs, csv)
      end
    end

    def check_existence_in_s3(digest_value)
      @sha1 = digest_value.partition("urn:sha1:").last
      @bucket.object(@sha1).exists?
    end
end
