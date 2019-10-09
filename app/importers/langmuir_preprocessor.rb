# frozen_string_literal: true
require 'csv'

##
# Utility service and methods that merge metadata from a CSV Pull List and MARCXml records
# into a format suitable for ingest by the curate CSV importer

class LangmuirPreprocessor
  attr_accessor :processed_csv

  ##
  # Initialize a preprocessor instance by supplying
  # @param [String] csv the path to a CSV file containing the expectd Pull List metadata
  def initialize(csv)
    @source_csv = CSV.read(csv, headers: true)
    directory = File.dirname(csv)
    extension = File.extname(csv)
    filename = File.basename(csv, extension)
    @processed_csv = File.join(directory, filename + "-processed.csv")
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
    @source_csv.each.with_index do |row, row_num|
      process_row(row, row_num + 2)
    end
  end

  def output_work_tree
    merge_csv = CSV.open(@processed_csv, 'w+', headers: true, write_headers: true)
    original_headers = @source_csv.headers
    merge_csv << additional_headers + original_headers
    @tree.each_value do |work|
      merge_csv << work[:metadata]
      two_sided = work[:filesets].count <= 2
      work[:filesets].keys.sort.each do |fileset_index|
        fileset = work[:filesets][fileset_index]
        fileset['fileset_label'] = make_label(fileset_index, two_sided)
        merge_csv << fileset
      end
    end
    merge_csv.close
  end

  def process_row(row, source_row)
    deduplication_key = row['Digital Object - Parent Identifier']
    return unless deduplication_key # skip blank rows in source csv
    @tree[deduplication_key] ||= { metadata: nil, filesets: {} } # create a placeholder if we don't have one for this key
    part, role = row['Filename'].scan(/P(\d+)_(ARCH|PROD)/).flatten
    part = part.to_i
    if part == 1 && role == 'ARCH'
      processed_row = CSV::Row.new(additional_headers, [source_row, deduplication_key, 'work'])
      processed_row << row.to_hash
      @tree[deduplication_key][:metadata] = processed_row
    end
    target_file = role == 'ARCH' ? 'preservation_master_file' : 'intermediate_file'
    @tree[deduplication_key][:filesets][part] ||= CSV::Row.new(additional_headers, [source_row, deduplication_key, 'fileset'])
    @tree[deduplication_key][:filesets][part][target_file] = row['Filename']
  end

  def make_label(side, two_sided)
    if two_sided
      side == 1 ? 'Front' : 'Back'
    else
      "Side #{side}"
    end
  end
end
