# frozen_string_literal: true

module ModularImporterDetailsDecorator
  def import
    @csv_import_detail = Zizia::CsvImportDetail.find_or_create_by(csv_import_id: @csv_import.id)
    @csv_import_detail.collection_id = @collection_id
    @csv_import_detail.depositor_id = @user_id
    @csv_import_detail.batch_id = @csv_import.id
    @csv_import_detail.deduplication_field = @deduplication_field
    @csv_import_detail.save
    super
  end

  def save_work
    super
    @row_number += 1
    @pre_ingest_work = Zizia::PreIngestWork.new(csv_import_detail_id: @csv_import_detail.id)
    @pre_ingest_work.save
  end

  def attach_files
    super
    @row_number += 1
    save_preservation_detail
    save_intermediate_detail
  end

  def save_preservation_detail
    @pre_ingest_file_preservation = Zizia::PreIngestFile.new(row_number: @row_number,
                                                             pre_ingest_work: @pre_ingest_work,
                                                             filename: @uploaded_file.preservation_master_file,
                                                             size: @uploaded_file.preservation_master_file.size)
    @pre_ingest_file_preservation.save
  end

  def save_intermediate_detail
    @pre_ingest_file_intermediate = Zizia::PreIngestFile.new(row_number: @row_number,
                                                             pre_ingest_work: @pre_ingest_work,
                                                             filename: @uploaded_file.intermediate_file,
                                                             size: @uploaded_file.intermediate_file.size)

    @pre_ingest_file_intermediate.save
  end
end
