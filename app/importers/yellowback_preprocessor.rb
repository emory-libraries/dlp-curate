# frozen_string_literal: true
require 'csv'

##
# Utility service and methods that merge metadata from a CSV Pull List and MARCXml records
# into a format suitable for ingest by the curate CSV importer

class YellowbackPreprocessor # rubocop:disable Metrics/ClassLength
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

  HEADER_FIELDS = [
    # Context fields to help humans compare this file to sources
    'pl_row',
    'work_id',
    'CSV title',
    # Fields extracted from the csv pull list
    'administrative_unit',
    'content_type',
    'data_classifications',
    'emory_ark',
    'emory_rights_statements',
    'holding_repository',
    'institution',
    'other_identifiers',
    'rights_statement',
    'system_of_record_ID',
    # Fields extracted from Alma MARC records
    'conference_name',
    'contributor',
    'copyright_date',
    'creator',
    'date_created',
    'date_digitized',
    'date_issued',
    'edition',
    'extent',
    'genre',
    'local_call_number',
    'place_of_production',
    'primary_language',
    'publisher',
    'series_title',
    'subject_geo',
    'subject_names',
    'subject_topics',
    'table_of_contents',
    'title',
    'uniform_title'
  ].freeze

  def merge
    merge_csv = CSV.open(@processed_csv, 'w+', headers: true, write_headers: true)
    merge_csv << HEADER_FIELDS
    @pull_list.each.with_index do |row, csv_index|
      mmsid = row['ALMA MMSID']
      record = @marc_records.xpath("//record/controlfield[@tag='001'][text()='#{mmsid}']/ancestor::record").first
      new_row = context_fields(csv_index, row)
      new_row += pull_list_mappings(row)
      new_row += alma_mappings(record, row)
      merge_csv << new_row
    end
    merge_csv.close
  end

  private

    def context_fields(csv_index, row)
      [
        csv_index + 2, # pl_row  (original row number from pull list)
        row['emory_ark'], # work_id
        row['CSV Title'] # title
      ]
    end

    def pull_list_mappings(row)
      [
        row['administrative_unit'],
        row['content_type'],
        row['data_classifications'],
        row['emory_ark'],
        row['emory_rights_statements'],
        row['holding_repository'],
        row['institution'],
        row['other_identifiers'],
        row['rights_statement'],
        row['system_of_record_ID']
      ]
    end

    def alma_mappings(record, row) # rubocop:disable Metrics/MethodLength
      [
        conference_name(record),
        contributor(record),
        copyright_date(record),
        creator(record),
        date_created(record),
        date_digitized(record),
        date_issued(record),
        edition(record),
        extent(record),
        genre(record),
        local_call_number(record),
        place_of_production(record),
        primary_language(record),
        publisher(record),
        series_title(record),
        subject_geo(record),
        subject_names(record),
        subject_topics(record),
        table_of_contents(record),
        title(record, row),
        uniform_title(record)
      ]
    end

    def conference_name(marc_record)
      extract_datafields(marc_record, '611')
    end

    def contributor(marc_record)
      [extract_datafields(marc_record, '700'),
       extract_datafields(marc_record, '710')].join('|')
    end

    def copyright_date(marc_record)
      date_created(marc_record)
    end

    def creator(marc_record)
      extract_datafields(marc_record, '100')
    end

    def date_created(marc_record)
      node_260_date = marc_record.xpath("./datafield[@tag='260']/subfield[@code='c']").text
      node_264_date = marc_record.xpath("./datafield[@tag='264']/subfield[@code='c']").text
      publication_date = clean_marc_date(node_260_date)
      production_date = clean_marc_date(node_264_date)
      if production_date
        production_date
      elsif publication_date
        publication_date
      else
        'XXXX'
      end
    end

    def date_digitized(marc_record)
      extract_datafields(marc_record, '583')
    end

    def date_issued(marc_record)
      date_created(marc_record)
    end

    def edition(marc_record)
      extract_datafields(marc_record, '250')
    end

    def extent(marc_record)
      extract_datafields(marc_record, '300')
    end

    def genre(marc_record)
      extract_datafields(marc_record, '655')
    end

    def local_call_number(marc_record)
      extract_datafields(marc_record, '090')
    end

    def place_of_production(marc_record)
      place_of_production_nodes = marc_record.xpath("./datafield[@tag='264']")
      place_of_production_nodes.xpath("./subfield[@code='a']").map { |s| s.text.scan(/(.+)\s[\:\;]$/) }.flatten.join('|')
    end

    def primary_language(marc_record)
      marc_record.xpath("./controlfield[@tag='008']").text.strip
    end

    def publisher(marc_record)
      publisher_nodes = marc_record.xpath("./datafield[@tag='264']")
      publisher_nodes.xpath("./subfield[@code='b']/text()").map { |s| s.text.scan(/(.+)[.,]$/) }.flatten.join('|')
    end

    def series_title(marc_record)
      extract_datafields(marc_record, '830')
    end

    def subject_geo(marc_record)
      subject_geo_nodes = marc_record.xpath("./datafield[@tag='651']")
      subject_geo_nodes.map { |n| n.xpath("./subfield/text()").map(&:text).join("--") }.join('|') #  join subfields with '--' and multiple datafields with '|'
    end

    def subject_names(marc_record)
      extract_datafields(marc_record, '600')
    end

    def subject_topics(marc_record)
      subject_topics_nodes = marc_record.xpath("./datafield[@tag='650']")
      subject_topics_nodes.map { |n| n.xpath("./subfield/text()").map(&:text).join("--") }.join('|') #  join subfields with '--' and multiple datafileds with '|'
    end

    def table_of_contents(marc_record)
      extract_datafields(marc_record, '505')
    end

    def title(marc_record, csv_row)
      title_nodes = marc_record.xpath("./datafield[@tag='245']")
      title_segments = title_nodes.xpath("./subfield[@code='a' or @code='b']/text()")
      alma_title = title_segments.map(&:text).join(" ").chomp("/").strip # join title segments with a space, then remove any trailing / or whitespace
      enumeration = csv_row["Enumeration"]
      if enumeration
        alma_title + " [#{enumeration}]"
      else
        alma_title
      end
    end

    def uniform_title(marc_record)
      extract_datafields(marc_record, '240')
    end

    def extract_datafields(marc_record, field_no)
      selected_nodes = marc_record.xpath("./datafield[@tag='#{field_no}']")
      concatenate_marc_datafields(selected_nodes)
    end

    def concatenate_marc_datafields(nodes = [])
      if nodes.count > 1
        nodes.map { |n| concatenate_marc_subfields(n) }.join('|')
      elsif nodes.count == 1
        concatenate_marc_subfields(nodes)
      end
    end

    def concatenate_marc_subfields(datafield)
      datafield.xpath('./subfield').map { |s| s.text.strip }.join(' ')
    end

    # Remove MARC puctuation from a date and return a 4-digit year or nil
    # e.g. "[1891.]" --> "1891"
    #      "19XX." --> nil
    #      "19th Cent."  --> nil
    def clean_marc_date(date_string)
      date_string.scan(/^\[?(\d{4})\D*/).flatten.first
    end
end
