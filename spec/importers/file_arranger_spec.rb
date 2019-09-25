# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileArranger, :clean do
  let(:work) { FactoryBot.create(:work) }
  let!(:file_set_front) { FactoryBot.create(:file_set, content: File.open(Rails.root.join('spec', 'fixtures', 'world.png')), title: ['Front']) }
  let!(:file_set_back) { FactoryBot.create(:file_set, content: File.open(Rails.root.join('spec', 'fixtures', 'world.png')), title: ['Back']) }
  let!(:file_set_neither) { FactoryBot.create(:file_set, content: File.open(Rails.root.join('spec', 'fixtures', 'world.png')), title: ['neither']) }

  it 'inserts Front and Back in order' do
    arranger = described_class.new(work: work, file_set: file_set_front)
    arranger.arrange
    arranger = described_class.new(work: work, file_set: file_set_back)
    arranger.arrange
    expect(work.ordered_members.to_a.first.title).to eq(['Front'])
    expect(work.ordered_members.to_a[1].title).to eq(['Back'])

    expect(work.thumbnail).to eq(file_set_front)
  end

  it 'inserts Back first if there is no front' do
    arranger = described_class.new(work: work, file_set: file_set_back)
    arranger.arrange
    expect(work.ordered_members.to_a.first.title).to eq(['Back'])
  end

  it 'inserts like normal if there is no label' do
    arranger = described_class.new(work: work, file_set: file_set_neither)
    arranger.arrange
    expect(work.ordered_members.to_a.first.title).to eq(['neither'])
  end
end
