# frozen_string_literal: true
require 'csv'
require 'ruby-progressbar'

##
# Utility service and methods that merge metadata from a CSV Pull List and MARCXml records
# into a format suitable for ingest by the curate CSV importer

class DamsPreprocessor
  attr_accessor :processed_csv

  ##
  # Initialize a preprocessor instance by supplying
  # @param [String] csv the path to a CSV file containing the expectd Pull List metadata
  # Change below was necessary to institute Source/Deposit Collection structure.
  # For more information, read the SOURCE_DEPOSIT_CHANGES_README.md in dlp-curate's root folder.
  def initialize(csv)
    convert = dams_header_map
    header_lambda = ->(name) { (convert[name] || name) }
    mapped_csv = CSV.open(csv, headers: true, header_converters: header_lambda, converters: :all)
    @source_csv = mapped_csv.read
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
    ['source_row', 'deduplication_key', 'type', 'fileset_label', 'preservation_master_file']
  end

  def dams_header_map
    { "Desc - Abstract" => "abstract", "Desc - Administrative Unit" => "administrative_unit",
      "Desc - Call Number/MSS Number" => "local_call_number", "Desc - Contact Information" => "contact_information",
      "Desc - Creator" => "creators", "Desc - Date Created" => "date_created", "Desc - Date Published" => "date_issued",
      "Desc - Genre - AAT" => "content_genres", "Desc - Genre - Legacy Data" => "content_genres",
      "Desc - Holding Repository" => "holding_repository", "Desc - Institution" => "institution",
      "Desc - Language - Primary" => "primary_language", "Desc - Notes" => "notes",
      "Desc - PID" => "emory_ark", "Desc - Place of Publication" => "place_of_production",
      "Desc - Publisher" => "publisher", "Desc - Rights Statement" => "emory_rights_statements",
      "Desc - RightsStatement.org Designation - URI" => "rights_statement_controlled", "Desc - Subject - Corporate Name - LCNAF" => "subject_names",
      "Desc - Subject - Geographic - LCSH" => "subject_geo", "Keywords" => "keywords",
      "Desc - Subject - Meeting Name - LCNAF" => "subject_names", "Desc - Subject - Personal Name - LCNAF" => "subject_names",
      "Desc - Subject - Topic - LCSH" => "subject_topics", "Desc - Subject - Uniform Title - LCNAF" => "uniform_title",
      "Desc - Table of Contents (Books)" => "table_of_contents", "Desc - Title" => "title",
      "Desc - Type of Resource" => "content_type", "Digital Object - Data Classification" => "data_classifications",
      "Digital Object - Visibility" => "visibility", "Rights - Copyright Date" => "copyright_date",
      "Rights - Copyright Holder" => "rights_holder", "Rights - Internal Note" => "internal_rights_note",
      "Rights - Sensitive/Objectionable Material" => "sensitive_material", "Rights - Sensitive/Objectionable Material Note" => "sensitive_material_note",
      "Source - Dimensions (L x W x H)" => "extent", "Source - Item Sublocation" => "sublocation",
      "Workflow - Date Digitized" => "date_digitized", "Workflow - Technician Name" => "transfer_engineer" }
  end

  def merge
    process_source_rows
    out_work_tree
  end

  def process_source_rows
    progressbar = ProgressBar.create(title: "Processing Source", total: @source_csv.size, format: '%t: |%B| %p%   ')
    @source_csv.each.with_index do |row, row_num|
      process_row(row, row_num + 2) if row['Digital Object - Parent Identifier'] # skip blank rows in the source csv
      progressbar.increment
    end
  end

  def out_work_tree
    merge_csv = CSV.open(@processed_csv, 'w+', headers: true, write_headers: true)
    merge_csv << @merged_headers
    progressbar = ProgressBar.create(title: "Writing works", total: @tree.size, format: '%t: |%B| %p%   ')
    @tree.each_value do |work|
      merge_csv << work[:metadata]
      work[:filesets].keys.sort.each do |fileset_index|
        fileset = work[:filesets][fileset_index]
        fileset['fileset_label'] = make_label(fileset_index)
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
    p_number = filename.scan(/P0+(\d+)/)[0][0].to_i
    target_file = 'preservation_master_file'
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

  def make_label(side)
    "Image #{side}"
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
