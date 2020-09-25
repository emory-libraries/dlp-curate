# frozen_string_literal: true
require 'csv'
require 'ruby-progressbar'

##
# Utility service and methods that merge metadata from a CSV Pull List and MARCXml records
# into a format suitable for ingest by the curate CSV importer

class LangmuirPreprocessor
  attr_accessor :processed_csv

  ##
  # Initialize a preprocessor instance by supplying
  # @param [String] csv the path to a CSV file containing the expectd Pull List metadata
  # Change below was necessary to institute Source/Deposit Collection structure.
  # For more information, read the SOURCE_DEPOSIT_CHANGES_README.md in dlp-curate's root folder.
  def initialize(csv)
    @source_csv = CSV.read(csv, headers: true)
    directory = File.dirname(csv)
    extension = File.extname(csv)
    filename = File.basename(csv, extension)
    @processed_csv = File.join(directory, filename + "-processed.csv")
    @merged_headers = exclusion_guard(additional_headers + @source_csv.headers)
    @tree = {}
  end

  def record_count
    @source_csv.count
  end

  def additional_headers
    ['source_row', 'deduplication_key', 'type', 'fileset_label', 'preservation_master_file', 'intermediate_file']
  end

  # process_source_rows builds
  # and
  # output_work_tree writes
  # a hash of hashes:
  # { work_id => {
  #      :metadata = CSV::Row,
  #      :filesets => {
  #            index1 => CSV::Row,
  #            index2 => CSV::Row,
  #            etc. for remaining sides/pages
  #            }
  #      }
  # }
  def merge
    process_source_rows
    output_work_tree
  end

  def process_source_rows
    progressbar = ProgressBar.create(title: "Processing Source", total: @source_csv.size, format: '%t: |%B| %p%   ')
    @source_csv.each.with_index do |row, row_num|
      process_row(row, row_num + 2) if row['Digital Object - Parent Identifier'] # skip blank rows in the source csv
      progressbar.increment
    end
  end

  def output_work_tree
    merge_csv = CSV.open(@processed_csv, 'w+', headers: true, write_headers: true)
    merge_csv << @merged_headers
    progressbar = ProgressBar.create(title: "Writing works", total: @tree.size, format: '%t: |%B| %p%   ')
    @tree.each_value do |work|
      merge_csv << work[:metadata]
      two_sided = work[:filesets].count <= 2
      work[:filesets].keys.sort.each do |fileset_index|
        fileset = work[:filesets][fileset_index]
        fileset['fileset_label'] = make_label(fileset_index, two_sided)
        merge_csv << fileset
      end
      progressbar.increment
    end
    merge_csv.close
  end

  def process_row(row, source_row_num)
    deduplication_key = row['Digital Object - Parent Identifier']
    sequence_number, target_file, metadata_row = extract_structure(row)
    @tree[deduplication_key] ||= { metadata: nil, filesets: {} } # create a placeholder if we don't have one for this key
    @tree[deduplication_key][:metadata] = extract_metadata(row, source_row_num) if metadata_row
    @tree[deduplication_key][:filesets][sequence_number] ||= CSV::Row.new(@merged_headers, [source_row_num, deduplication_key, 'fileset'])
    @tree[deduplication_key][:filesets][sequence_number][target_file] = relative_path_to_file(row)
  end

  def extract_structure(row)
    filename = row['Filename']
    p_number = filename.scan(/P0+(\d+)_(ARCH|PROD)/)[0][0].to_i
    target_file = filename.include?('ARCH') ? 'preservation_master_file' : 'intermediate_file'
    metadata_row = p_number == 1 && target_file == 'preservation_master_file'
    [p_number, target_file, metadata_row]
  end

  def extract_metadata(row, source_row_num)
    deduplication_key = row['Digital Object - Parent Identifier']
    processed_row = CSV::Row.new(additional_headers, [source_row_num, deduplication_key, 'work'])
    processed_row << row.to_hash
  end

  def relative_path_to_file(row)
    absolute_path = row['Path'] # e.g. "::nasn2dmz.cc.emory.edu:dmfiles:MARBL:Manuscripts:MSS_1218_Langmuir:ARCH:B071:MSS1218_B071_I205_P0001_ARCH.tif"
    relative_path = absolute_path.gsub(/::(\w+\.)*\w+:/, '') # remove any initial ::hostname.domain: prefix
    relative_path.tr(':', '/') # convert path segment separators from colons to forward slashes
  end

  def make_label(side, two_sided)
    if two_sided
      side == 1 ? 'Front' : 'Back'
    else
      "Image #{side}"
    end
  end

  # Change below was necessary to institute Source/Deposit Collection structure.
  # For more information, read the SOURCE_DEPOSIT_CHANGES_README.md in dlp-curate's root folder.
  def exclusion_guard(arr)
    arr | required_fields
  end

  def required_fields
    ['source_collection_id']
  end
end
