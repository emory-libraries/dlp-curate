# frozen_string_literal: true
require 'rails_helper'
require 'support/file_set_helper'

describe ReCharacterizationService, :clean do
  let(:filename)     { 'sample-file.pdf' }
  let(:path_on_disk) { File.join(fixture_path, filename) }
  let(:file)         { Hydra::PCDM::File.new }

  before do
    skip 'external tools not installed for CI environment' if ENV['CI']
    Hydra::Works::CharacterizationService.run(file, path_on_disk)
    file.content = "junk"
    file.save
  end

  describe "#empty_characterization" do
    let(:service) { described_class.new(file) }
    let(:fields) { service.send(:characterization_setters) }
    let(:values) { fields.map { |f| file.send(f)&.first }.compact }

    it 'works' do
      expect(values.size).to be > 1
      service.empty_characterization
      new_values = fields.map { |f| file.send(f)&.first }.compact
      expect(new_values).to be_empty
    end
  end
end
