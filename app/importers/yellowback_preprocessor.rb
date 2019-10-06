# frozen_string_literal: true
require 'csv'

##
# Utility service and methods that merge metadata from a CSV Pull List and MARCXml records
# into a format suitable for ingest by the curate CSV importer

class YellowbackPreprocessor
  attr_accessor :processed_csv

  ##
  # Initialize a preprocessor instance by supplying
  # @param [String] csv the path to a CSV file containing the expectd Pull List metadata
  # @param [String] marcxml the path to an XML file containing one or more MARCXml records
  def initialize(csv, marcxml)
    @pull_list = CSV.read(csv, headers: true)
    @marc_records = Nokogiri::XML(File.open(marcxml))
    directory = File.dirname(csv)
    extension = File.extname(csv)
    filename = File.basename(csv, extension)
    @processed_csv = File.join(directory, filename + "-merged.csv")
  end

  def merge
    merge_csv = CSV.open(@processed_csv, 'w+', headers: true, write_headers: true)
    headers = ['pl_row', 'work_id', 'title']
    merge_csv << headers
    @pull_list.each.with_index do |row, csv_index|
      new_row = [
        csv_index + 2,    # pl_row  (original row number from pull list)
        row['emory_ark'], # work_id
        row['CSV Title']  # title
      ]
      merge_csv << new_row
    end
    merge_csv.close
  end
end
