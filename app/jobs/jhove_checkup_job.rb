# frozen_string_literal: true
require 'nokogiri'

class JhoveCheckupJob < Hyrax::ApplicationJob
  def perform(jhove_path, tifs_path)
    tif_file_paths = Dir.glob("#{tifs_path}/**/*.tif")
    CSV.open("config/emory/problem_files.csv", "w") do |csv|
      tif_file_paths.each do |file|
        xml_output, errors, status = Open3.capture3("#{jhove_path} -m TIFF-hul -h XML #{file}")
        Sidekiq.logger.info "There was an error running JHOVE for #{file} #{errors}" unless status&.success?
        document = Nokogiri::XML(xml_output)
        # making status text lower case and then checking if "not" exists since there could be couple of
        # instances for a bad file as follows:
        # Eg: `Not well-formed`
        # Eg: `Well-formed, but not valid`
        csv << [file] if document.css('//status').to_xml.downcase.include?("not")
      end
    end
  end
end
