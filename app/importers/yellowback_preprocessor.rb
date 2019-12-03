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
  # @param [String] replacement_path AWS target path to replace 'Volumes' in source data
  # @param [String] digitization the fileset mappings to use (:limb or :kirtas)
  def initialize(csv, marcxml, replacement_path = 'Yellowbacks', workflow = :kirtas)
    @pull_list = CSV.read(csv, headers: true)
    @marc_records = Nokogiri::XML(File.open(marcxml))
    @workflow = workflow
    @replacement_path = replacement_path
    directory = File.dirname(csv)
    extension = File.extname(csv)
    filename = File.basename(csv, extension)
    @processed_csv = File.join(directory, filename + "-merged.csv")
  end

  HEADER_FIELDS = [
    # Context fields to help humans compare this file to sources
    'deduplication_key',
    'pl_row',
    'CSV title',
    'type',
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
    'visibility',
    # Fields extracted from Alma MARC records
    'conference_name',
    'contributors',
    'copyright_date',
    'creator',
    'date_created',
    'date_digitized',
    'date_issued',
    'edition',
    'extent',
    'content_genres',
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
    'uniform_title',
    # Fileset fields
    'fileset_label',
    'preservation_master_file',
    'service_file',
    'intermediate_file',
    'transcript_file',
    'extracted',
    'pcdm_use'
  ].freeze

  def merge
    merge_csv = CSV.open(@processed_csv, 'w+', headers: true, write_headers: true)
    merge_csv << HEADER_FIELDS
    @pull_list.each.with_index do |row, csv_index|
      mmsid = row['ALMA MMSID']
      record = @marc_records.xpath("//record/controlfield[@tag='001'][text()='#{mmsid}']/ancestor::record").first
      new_row = context_fields(csv_index, row, 'work')
      new_row += pull_list_mappings(row)
      new_row += alma_mappings(record, row)
      new_row += file_placeholder
      merge_csv << new_row
      add_file_rows(csv_index, merge_csv, row)
    end
    merge_csv.close
  end

  private

    def context_fields(csv_index, row, type)
      [
        row['emory_ark'], # deduplication_key
        csv_index + 2, # pl_row  (original row number from pull list)
        row['CSV Title'], # title
        type # row type (work | fileset)
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
        row['system_of_record_ID'],
        row['visibility']
      ]
    end

    def alma_mappings(record, row) # rubocop:disable Metrics/MethodLength
      [
        conference_name(record),
        contributors(record),
        copyright_date(record),
        creator(record),
        date_created(record),
        date_digitized(record),
        date_issued(record),
        edition(record),
        extent(record),
        content_genres(record),
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

    def add_file_rows(csv_index, merge_csv, row) # rubocop:disable Metrics/CyclomaticComplexity
      merge_csv << pdf_row(csv_index, row) if row['PDF_Path'].present? && row['PDF_Cnt'] == '1'

      merge_csv << ocr_row(csv_index, row) if row['OCR_Path'].present? && row['OCR_Cnt'] == '1'

      merge_csv << mets_row(csv_index, row) if row['METS_Path'].present? && row['METS_Cnt'] == '1'

      pages = row['Disp_Cnt'].to_i

      (1..pages).each do |page|
        merge_csv << file_row(csv_index, row, page)
      end
    end

    def pdf_row(csv_index, row)
      case @workflow
      when :kirtas
        pdf = row['PDF_Path'].sub("Volumes", @replacement_path)
      when :limb
        pdf = File.join(row['PDF_Path'].sub("Volumes", @replacement_path), "#{row['Barcode']}.pdf")
      end
      new_row = context_fields(csv_index, row, 'fileset') + pull_list_placeholder + alma_placeholder
      new_row + file_mappings(fileset_label: 'PDF for volume', preservation_master_file: pdf)
    end

    def ocr_row(csv_index, row)
      ocr = row['OCR_Path'].sub("Volumes", @replacement_path)
      new_row = context_fields(csv_index, row, 'fileset') + pull_list_placeholder + alma_placeholder
      new_row + file_mappings(fileset_label: 'OCR Output for Volume', preservation_master_file: ocr, pcdm_use: ::FileSet::SUPPLEMENTAL)
    end

    def mets_row(csv_index, row)
      case @workflow
      when :kirtas
        mets = row['METS_Path'].sub("Volumes", @replacement_path)
      when :limb
        mets = File.join(row['METS_Path'].sub("Volumes", @replacement_path), "#{row['Barcode']}.mets.xml")
      end
      new_row = context_fields(csv_index, row, 'fileset') + pull_list_placeholder + alma_placeholder
      new_row + file_mappings(fileset_label: 'METS File', preservation_master_file: mets, pcdm_use: ::FileSet::SUPPLEMENTAL)
    end

    def file_row(csv_index, row, page) # rubocop:disable Metrics/MethodLength
      case @workflow
      when :kirtas
        page_number = format("%04d", page)
        extract_field = 'POS_Path'
        extract_extension = 'pos'
      when :limb
        page_number = format("%08d", page)
        extract_field = 'ALTO_Path'
        extract_extension = 'xml'
      end

      image       = relative_filename(row['Disp_Path'],   page_number, 'tif')
      transcript  = relative_filename(row['Txt_Path'],    page_number, 'txt')
      extract     = relative_filename(row[extract_field], page_number, extract_extension)

      new_row = context_fields(csv_index, row, 'fileset') + pull_list_placeholder + alma_placeholder
      new_row + file_mappings(fileset_label: "Page #{page}", preservation_master_file: image, transcript_file: transcript, extracted: extract)
    end

    def relative_filename(source_path, page_number, extension)
      path = source_path.sub("Volumes", @replacement_path)
      File.join(path, "#{page_number}.#{extension}")
    end

    def file_mappings(args = {})
      [
        args[:fileset_label],
        args[:preservation_master_file],
        args[:service_file],
        args[:intermediate_file],
        args[:transcript_file],
        args[:extracted],
        args[:pcdm_use]
      ]
    end

    # return an array to pad the correct number of colums for alma fields
    def alma_placeholder
      alma_mappings(Nokogiri::XML("<empty_doc/>"), {}).fill(nil)
    end

    # return an array to pad the correct number of colums for pull list fields
    def pull_list_placeholder
      pull_list_mappings({}).fill(nil)
    end

    def file_placeholder
      file_mappings
    end

    def conference_name(marc_record)
      extract_datafields(marc_record, '611')
    end

    def contributors(marc_record)
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

    def content_genres(marc_record)
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
        alma_title + " [#{enumeration.strip}]"
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
