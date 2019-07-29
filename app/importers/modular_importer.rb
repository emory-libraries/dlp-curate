require 'zizia'

class ModularImporter
  def initialize(csv_file)
    @csv_file = csv_file
    raise "Cannot find expected input file #{csv_file}" unless File.exist?(csv_file)
  end

  def import
    file = File.open(@csv_file)
    Zizia::Importer.new(parser: Zizia::CsvParser.new(file: file), record_importer: Zizia::HyraxRecordImporter.new).import
    file.close # Note that we must close any files we open.
  end
end
