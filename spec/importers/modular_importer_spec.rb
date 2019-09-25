# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ModularImporter, :clean do
  let(:modular_csv) { 'spec/fixtures/csv_import/good/batch_of_ten.csv' }
  let(:user) { ::User.batch_user }
  let(:collection) { FactoryBot.build(:collection_lw) }
  let(:csv_import) do
    import = Zizia::CsvImport.new(user: user, fedora_collection_id: collection.id)
    import.update_actor_stack = 'HyraxMetadataOnly'
    File.open(modular_csv) { |f| import.manifest = f }
    import
  end

  it "imports a csv" do
    expect { ModularImporter.new(csv_import).import }.to change { CurateGenericWork.count }.by 5
  end
end
