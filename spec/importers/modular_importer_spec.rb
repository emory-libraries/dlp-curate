# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ModularImporter, :clean do
  let(:modular_csv) { 'spec/fixtures/csv_import/zizia_basic.csv' }
  let(:user) { ::User.batch_user }

  it "imports a csv" do
    expect { ModularImporter.new(modular_csv).import }.to change { CurateGenericWork.count }.by 3
  end
end
