# frozen_string_literal: true
require 'csv'
require 'ruby-progressbar'

##
# Utility service and methods that merge metadata from a CSV Pull List and MARCXml records
# into a format suitable for ingest by the curate CSV importer

class YellowbackPreprocessor
  attr_accessor :processed_csv

  ##
  # Initialize a preprocessor instance by supplying
  # @param [String] csv the path to a CSV file containing the expectd Pull List metadata
  # @param [String] marcxml the path to an XML file containing one or more MARCXml records
  # @param [String] replacement_path AWS target path to replace 'Volumes' in source data
  # @param [String] digitization the fileset mappings to use (:limb or :kirtas)
  def initialize(csv,
                 marcxml,
                 importer,
                 workflow = :kirtas,
                 start_page = 1,
                 add_transcript = false,
                 add_ocr_output = false)
    @pull_list = CSV.read(csv, headers: true)
    @marc_records = Nokogiri::XML(File.open(marcxml))
    @workflow = workflow
    @replacement_path = 'Yellowbacks'
    @is_for_bulkrax = importer == 'bulkrax'
    @proper_model_or_type_work = @is_for_bulkrax ? 'CurateGenericWork' : 'work'
    @proper_model_or_type_fileset = @is_for_bulkrax ? 'FileSet' : 'fileset'
    @add_transcript = add_transcript
    @add_ocr_output = add_ocr_output
    directory = File.dirname(csv)
    extension = File.extname(csv)
    filename = File.basename(csv, extension)
    @processed_csv = File.join(directory, filename + "-merged.csv")
    @base_offset = 1 - start_page
  end

  # Change below was necessary to institute Source/Deposit Collection structure.
  # For more information, read the SOURCE_DEPOSIT_CHANGES_README.md in dlp-curate's root folder.
  def header_fields
    [
      # Context fields to help humans compare this file to sources
      'deduplication_key',
      'pl_row',
      'CSV title',
      @is_for_bulkrax ? 'model' : 'type',
      'parent',
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
      'source_collection_id',
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
      'pcdm_use',
      'file',
      'file_types'
    ]
  end

  def merge
    merge_csv = CSV.open(@processed_csv, 'w+', headers: true, write_headers: true)
    merge_csv << header_fields
    progressbar = ProgressBar.create(title: "Processing Rows", total: @pull_list.size, format: '%t: |%B| %p%  ')
    @pull_list.each.with_index do |row, csv_index|
      record = @marc_records.xpath("//record/controlfield[@tag='001'][text()='#{row['ALMA MMSID']}']/ancestor::record").first
      new_row = context_fields(csv_index, row, @proper_model_or_type_work)
      new_row += pull_list_mappings(row)
      new_row += alma_mappings(record, row)
      new_row += file_placeholder
      merge_csv << new_row
      add_file_rows(csv_index, merge_csv, row)
      progressbar.increment
    end
    merge_csv.close
  end

  private

    def context_fields(csv_index, row, type, for_file_set = false)
      [
        for_file_set && @is_for_bulkrax ? '' : row['deduplication_key'], # deduplication_key
        csv_index + 2, # pl_row  (original row number from pull list)
        row['CSV Title'], # title
        type, # row type (work | fileset)
        populate_parent_field(for_file_set, row)
      ]
    end

    # Change below was necessary to institute Source/Deposit Collection structure.
    # For more information, read the SOURCE_DEPOSIT_CHANGES_README.md in dlp-curate's root folder.
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
        row['source_collection_id'],
        row['system_of_record_ID'],
        row['visibility']
      ]
    end

    def alma_mappings(record, row)
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

    def add_file_rows(csv_index, merge_csv, row)
      process_standard_file_rows(merge_csv, csv_index, row)
      process_optional_file_rows(merge_csv, csv_index, row)

      pages = row['Disp_Cnt'].to_i

      (1..pages).each do |page|
        merge_csv << file_row(csv_index, row, page)
      end
    end

    def process_standard_file_rows(merge_csv, csv_index, row)
      merge_csv << pdf_row(csv_index, row) if should_add_pdf(row)
      merge_csv << ocr_row(csv_index, row) if should_add_ocr(row)
      merge_csv << mets_row(csv_index, row) if row['METS_Path'].present? && row['METS_Cnt'] == '1'
    end

    def process_optional_file_rows(merge_csv, csv_index, row)
      merge_csv << ondemand_transcript_row(csv_index, row) if should_add_pdf(row) && @add_transcript
      merge_csv << ondemand_ocr_row(csv_index, row) if !should_add_ocr(row) && should_add_pdf(row) && @add_ocr_output
    end

    def should_add_pdf(row)
      row['PDF_Path'].present? && row['PDF_Cnt'] == '1'
    end

    def should_add_ocr(row)
      row['OCR_Path'].present? && row['OCR_Cnt'] == '1'
    end

    def pdf_row(csv_index, row)
      pdf = pull_pdf(row)
      new_row = build_new_row(csv_index, row, pdf_fileset_title)
      filename = pull_filename_from_path(pdf)

      build_complete_pdf_row(new_row, pdf, filename)
    end

    def ocr_row(csv_index, row)
      ocr = row['OCR_Path'].sub("Volumes", @replacement_path)
      new_row = build_new_row(csv_index, row, ocr_fileset_title)
      filename = pull_filename_from_path(ocr)

      build_complete_ocr_row(new_row, ocr, filename)
    end

    def mets_row(csv_index, row)
      mets = pull_mets(row)
      new_row = build_new_row(csv_index, row, mets_fileset_title)
      filename = pull_filename_from_path(mets)

      build_complete_mets_row(new_row, mets, filename)
    end

    def ondemand_transcript_row(csv_index, row)
      transcript = pull_and_transform_pdf(row, '.txt')
      new_row = build_new_row(csv_index, row, transcript_fileset_title)
      filename = pull_filename_from_path(transcript)

      build_complete_pdf_row(new_row, transcript, filename)
    end

    def ondemand_ocr_row(csv_index, row)
      ocr = pull_and_transform_pdf(row, '.xml')
      new_row = build_new_row(csv_index, row, ocr_fileset_title)
      filename = pull_filename_from_path(ocr)

      build_complete_ocr_row(new_row, ocr, filename)
    end

    def file_row(csv_index, row, page)
      page_number, extract_field, extract_extension = pull_file(page)
      image, transcript, extract = pull_file_paths(page_number, extract_field, extract_extension, row)
      fileset_title = "Page #{page - @base_offset}"
      new_row = build_new_row(csv_index, row, fileset_title)

      build_complete_file_row(new_row, fileset_title, image, transcript, extract)
    end

    def pdf_fileset_title
      'PDF for volume'
    end

    def ocr_fileset_title
      'OCR Output for Volume'
    end

    def mets_fileset_title
      'METS File'
    end

    def transcript_fileset_title
      'Transcript for Volume'
    end

    def pull_file_paths(page_number, extract_field, extract_extension, row)
      [relative_filename(row['Disp_Path'], page_number, 'tif'),
       relative_filename(row['Txt_Path'], page_number, 'txt'),
       pull_extract_field(row, extract_field, page_number, extract_extension)]
    end

    def pull_extract_field(row, extract_field, page_number, extract_extension)
      return if @workflow == :kirtas
      relative_filename(row[extract_field], page_number, extract_extension)
    end

    def build_complete_pdf_row(new_row, pdf, filename)
      generic_complete_row_builder(new_row, pdf, filename, pdf_fileset_title, ::FileSet::PRIMARY)
    end

    def build_complete_ocr_row(new_row, ocr, filename)
      generic_complete_row_builder(new_row, ocr, filename, ocr_fileset_title, ::FileSet::SUPPLEMENTAL)
    end

    def build_complete_mets_row(new_row, mets, filename)
      generic_complete_row_builder(new_row, mets, filename, mets_fileset_title, ::FileSet::PRESERVATION)
    end

    def generic_complete_row_builder(build_on_row, file_path, filename, title, pcdm_use)
      build_on_row + file_mappings(
        fileset_label:            @is_for_bulkrax ? nil : title,
        preservation_master_file: file_path,
        pcdm_use:                 pcdm_use,
        file:                     @is_for_bulkrax && filename.present? ? filename : nil,
        file_types:               @is_for_bulkrax ? build_file_type_pair(filename, 'preservation_master_file') : nil
      )
    end

    def build_complete_file_row(new_row, fileset_title, image, transcript, extract)
      new_row + file_mappings(
        fileset_label:            @is_for_bulkrax ? nil : fileset_title,
        preservation_master_file: image,
        transcript_file:          transcript,
        extracted:                extract,
        pcdm_use:                 @is_for_bulkrax ? 'Primary Content' : nil,
        file:                     @is_for_bulkrax ? build_file_list([image, transcript, extract]) : nil,
        file_types:               process_file_file_types(image, transcript, extract)
      )
    end

    def process_file_file_types(image, transcript, extract)
      return unless @is_for_bulkrax
      build_multiple_file_types(
        [
          [pull_filename_from_path(image), 'preservation_master_file'],
          [pull_filename_from_path(transcript), 'transcript'],
          [pull_filename_from_path(extract), 'extracted_text']
        ]
      )
    end

    def pull_pdf(row)
      case @workflow
      when :kirtas
        row['PDF_Path'].sub("Volumes", @replacement_path)
      when :limb
        File.join(row['PDF_Path'].sub("Volumes", @replacement_path), "#{row['Barcode']}.pdf")
      end
    end

    def pull_mets(row)
      case @workflow
      when :kirtas
        row['METS_Path'].sub("Volumes", @replacement_path)
      when :limb
        File.join(row['METS_Path'].sub("Volumes", @replacement_path), "#{row['Barcode']}.mets.xml")
      end
    end

    def pull_file(page)
      case @workflow
      when :kirtas
        [format("%04d", page - @base_offset), 'POS_Path', 'pos']
      when :limb
        [format("%08d", page - @base_offset), 'ALTO_Path', 'xml']
      end
    end

    def pull_and_transform_pdf(row, new_ext)
      unaltered_path = pull_pdf(row)
      unaltered_path.gsub('.pdf', new_ext)
    end

    def build_new_row(csv_index, row, fileset_title)
      context_fields(
        csv_index,
        row,
        @proper_model_or_type_fileset,
        @is_for_bulkrax ? true : false
      ) + pull_list_placeholder + alma_placeholder(@is_for_bulkrax ? fileset_title : false)
    end

    def build_file_list(arr)
      return if arr.compact.empty?
      arr.compact.map { |f| pull_filename_from_path(f) }.join(';')
    end

    def pull_filename_from_path(path)
      path&.split('/')&.last
    end

    def build_file_type_pair(filename, type)
      [filename, type].join(':')
    end

    def build_multiple_file_types(arr_of_arrs)
      arr_of_arrs.map do |arr|
        build_file_type_pair(arr[0], arr[1]) if arr[0].present?
      end.compact.join('|')
    end

    def populate_parent_field(for_file_set, row)
      return unless @is_for_bulkrax
      if for_file_set
        row['deduplication_key']
      else
        row['source_collection_id']
      end
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
        args[:pcdm_use],
        args[:file],
        args[:file_types]
      ]
    end

    # return an array to pad the correct number of colums for alma fields
    def alma_placeholder(title_to_inject = nil)
      blank_mappings = alma_mappings(Nokogiri::XML("<empty_doc/>"), {}).fill(nil)
      blank_mappings[-2] = title_to_inject if title_to_inject
      blank_mappings
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
       extract_datafields(marc_record, '710')]&.compact&.join('|')
    end

    def copyright_date(marc_record)
      clean_marc_date(marc_record.xpath("./datafield[@tag='264' and @ind2='4']/subfield[@code='c']").text)
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
      dd = extract_datafields(marc_record, '583')
      extract_date_digitized(dd)
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

    def extract_date_digitized(datefields)
      first_date = datefields&.split('|')&.first
      return first_date[0..3] if !first_date.nil? && first_date.size >= 4
      datefields
    end
end
