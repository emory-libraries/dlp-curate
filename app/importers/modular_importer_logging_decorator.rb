# frozen_string_literal: true

# This class mirrors the methods in the ModularImporter class
# and adds logging to them
require 'benchmark'

module ModularImporterLoggingDecorator
  def import
    Rails.logger.info "[zizia] Starting import with ID: #{csv_import.id}\n"
    super
  end

  def save_work
    benchmark = Benchmark.measure { super }
    Rails.logger.info "[zizia] Saved work with the title: \"#{work.title.first}\" and id: #{work.id}\n"
    Rails.logger.info "[zizia] Time saving work: #{benchmark}\n"
  end

  def create_hyrax_uploaded_file
    Rails.logger.info "[zizia] Creating HyraxUploadedFile\n"
    super
  end

  def attach_files
    benchmark = Benchmark.measure { super }
    Rails.logger.info "[zizia] Attached files to the work \n"
    Rails.logger.info "[zizia] AttachFilesToWork Time: #{benchmark}\n"
  end
end
