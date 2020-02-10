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
        FileSet.all.each do |file_set|
          check_binary(file_set, csv) unless file_set.files.empty?
        end
      end
    end
  end

  private

    def check_binary(file_set, csv)
      file_set.files.each do |file|
        next if file.digest.empty?
        sha1 = file.digest.first.to_s.partition("urn:sha1:").last
        next if @bucket.object(sha1).exists?
        csv << [file&.id]
      end
    end
end
