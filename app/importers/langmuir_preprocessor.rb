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
  def initialize(csv, importer)
    @source_csv = CSV.read(csv, headers: true)
    @is_for_bulkrax = importer == 'bulkrax'
    @fileset_model_or_type = @is_for_bulkrax ? 'FileSet' : 'fileset'
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
    ['source_row', 'deduplication_key', @is_for_bulkrax ? 'model' : 'type', 'parent',
     'file', 'file_types', 'pcdm_use', 'fileset_label', 'preservation_master_file',
     'intermediate_file']
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
      process_work_filesets_output(work, two_sided, merge_csv)
      progressbar.increment
    end
    merge_csv.close
  end

  def process_work_filesets_output(work, two_sided, merge_csv)
    work[:filesets].keys.sort.each do |fileset_index|
      fileset = work[:filesets][fileset_index]

      process_fileset_title_label(fileset, fileset_index, two_sided)
      process_fileset_file_and_file_type(fileset) if @is_for_bulkrax
      merge_csv << fileset
    end
  end

  def process_fileset_title_label(fileset, fileset_index, two_sided)
    fileset_label = make_label(fileset_index, two_sided)
    @is_for_bulkrax ? fileset['title'] = fileset_label : fileset['fileset_label'] = fileset_label
  end

  def process_fileset_file_and_file_type(fileset)
    pres_filename = fileset['preservation_master_file']&.split('/')&.last
    int_filename = fileset['intermediate_file']&.split('/')&.last
    pres_file_type_chunk = "#{pres_filename}:preservation_master_file" if pres_filename.present?
    int_file_type_chunk = "#{int_filename}:intermediate_file" if int_filename.present?

    fileset['file'] = [pres_filename, int_filename].compact.join(';')
    fileset['file_types'] = [pres_file_type_chunk, int_file_type_chunk].compact.join('|')
  end

  def process_row(row, source_row_num)
    parent = row['Digital Object - Parent Identifier']
    deduplication_key = @is_for_bulkrax ? '' : parent
    @sequence_number, @target_file, @metadata_row = extract_structure(row)
    @tree[parent] ||= { metadata: nil, filesets: {} } # create a placeholder if we don't have one for this key

    populate_tree_row_metadata(parent, row, source_row_num)
    populate_tree_row_fileset(parent, source_row_num, deduplication_key, row)
  end

  def populate_tree_row_metadata(parent, row, source_row_num)
    @tree[parent][:metadata] = extract_metadata(row, source_row_num) if @metadata_row
  end

  def populate_tree_row_fileset(parent, source_row_num, deduplication_key, row)
    @tree[parent][:filesets][@sequence_number] ||= CSV::Row.new(
      @merged_headers, [source_row_num, deduplication_key, @fileset_model_or_type, parent, '', '', 'Primary Content']
    )
    @tree[parent][:filesets][@sequence_number][@target_file] = relative_path_to_file(row)
  end

  def extract_structure(row)
    @fileset_filename = row['Filename']
    p_number = @fileset_filename.scan(/P0+(\d+)_(ARCH|PROD)/)[0][0].to_i
    target_file = @fileset_filename.include?('ARCH') ? 'preservation_master_file' : 'intermediate_file'
    metadata_row = p_number == 1 && target_file == 'preservation_master_file'
    [p_number, target_file, metadata_row]
  end

  def extract_metadata(row, source_row_num)
    parent = row['source_collection_id']
    deduplication_key = row['Digital Object - Parent Identifier']
    model_or_type = @is_for_bulkrax ? 'CurateGenericWork' : 'work'
    processed_row = CSV::Row.new(additional_headers, [source_row_num, deduplication_key, model_or_type, parent, '', '', ''])
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
