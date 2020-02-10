# frozen_string_literal: true
require 'aws-sdk-s3'

class CheckBinariesJob < Hyrax::ApplicationJob
  def perform(bucket, file_set_id = nil)
    CSV.open("config/emory/check_binaries_results.csv", "w") do |csv|
      @s3 = Aws::S3::Resource.new(region: 'us-east-1')
      @bucket = @s3.bucket(bucket)

      if file_set_id.present?
        fs = FileSet.find(file_set_id)
        check_binary(fs, csv)
      else
        check_all_file_sets
      end
    end
  end

  private

    def check_binary(file_set, csv)
      file_set.files.each do |file|
        next if file.digest.empty? || check_existence_in_s3(file)
        csv << [file_set.member_of_work_ids.join(','), file_set.id, file&.id, @sha1]
      end
    end

    def check_all_file_sets
      FileSet.all.each do |file_set|
        check_binary(file_set, csv) unless file_set.files.empty?
      end
    end

    def check_existence_in_s3(file)
      @sha1 = file.digest.first.to_s.partition("urn:sha1:").last
      @bucket.object(@sha1).exists?
    end
end
