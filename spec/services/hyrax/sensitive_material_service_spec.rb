RSpec.describe Hyrax::SensitiveMaterialService do
  before do
    # Configure QA to use fixtures
    qa_fixtures = { local_path: File.expand_path('config/authorities') }
    allow(Qa::Authorities::Local).to receive(:config).and_return(qa_fixtures)
  end

  let(:service) { described_class.new }

  describe "#select_all_options" do
    it "has a select list" do
      expect(service.select_all_options).to include([true, true])
    end
  end
end
