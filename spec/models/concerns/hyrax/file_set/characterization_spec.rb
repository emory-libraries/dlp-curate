require 'rails_helper'

RSpec.describe Hyrax::FileSet::Characterization do
  let(:file) { Hydra::PCDM::File.new }

  describe "file" do
    it 'has new technical metadata' do
      expect(file).to respond_to(:file_path)
      expect(file).to respond_to(:creating_application_name)
      expect(file).to respond_to(:creating_os)
      expect(file).to respond_to(:puid)
    end
  end
end
