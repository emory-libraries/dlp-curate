# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Collection do
  context "Solr document for collections" do
    let(:collection)     { FactoryBot.build(:collection_lw) }
    let(:work1)          { FactoryBot.build(:work, id: 'wk1', title: ['Work 1']) }
    let(:work2)          { FactoryBot.build(:work, id: 'wk2', title: ['Work 2']) }
    let(:work3)          { FactoryBot.build(:work, id: 'wk3', title: ['Work 3']) }
    let(:solr_doc)       { collection.to_solr }

    it "indexes a count of 0 child works for empty collections" do
      expect(solr_doc['member_works_count_isi']).to eq 0
    end

    it "indexes the correct count of child works for populated collections" do
      works = [work1, work2, work3]
      works.each { |w| collection.ordered_members << w }
      collection.save!
      collection.reload
      expect(solr_doc['member_works_count_isi']).to eq 3
    end
  end

  describe "#holding_repository" do
    subject { described_class.new }
    let(:holding_repository) { ['Woodruff'] }

    context "with new collection" do
      its(:holding_repository) { is_expected.to be_empty }
    end

    context "with a collection that has a holding_repository" do
      subject do
        described_class.create.tap do |col|
          col.holding_repository = holding_repository
        end
      end
      its(:holding_repository) { is_expected.to eq holding_repository }
    end
  end

  describe "#administrative_unit" do
    subject { described_class.new }
    let(:administrative_unit) { ['LTDS'] }

    context "with new collection" do
      its(:administrative_unit) { is_expected.to be_empty }
    end

    context "with a collection that has an administrative_unit" do
      subject do
        described_class.create.tap do |col|
          col.administrative_unit = administrative_unit
        end
      end
      its(:administrative_unit) { is_expected.to eq administrative_unit }
    end
  end

  describe "#creator" do
    subject { described_class.new }
    let(:creator) { ['William Shakespeare'] }

    context "with new collection" do
      its(:creator) { is_expected.to be_empty }
    end

    context "with a collection that has a creator" do
      subject do
        described_class.create.tap do |col|
          col.creator = creator
        end
      end
      its(:creator) { is_expected.to eq(['William Shakespeare']) }
    end
  end

  describe "#contributors" do
    subject { described_class.new }
    let(:contributors) { ['Leo Tolstoy'] }

    context "with new collection" do
      its(:contributors) { is_expected.to be_empty }
    end

    context "with a collection that has contributors" do
      subject do
        described_class.create.tap do |col|
          col.contributors = contributors
        end
      end
      its(:contributors) { is_expected.to eq(['Leo Tolstoy']) }
    end
  end

  describe "#abstract" do
    subject { described_class.new }
    let(:abstract) { 'This is an abstract of an ETD' }

    context "with new collection" do
      its(:abstract) { is_expected.to be_falsey }
    end

    context "with a collection that has an abstract" do
      subject do
        described_class.create.tap do |col|
          col.abstract = abstract
        end
      end
      its(:abstract) { is_expected.to include 'abstract of an ETD' }
    end
  end

  describe "#primary_language" do
    subject { described_class.new }
    let(:primary_language) { 'English' }

    context "with new collection" do
      its(:primary_language) { is_expected.to be_falsey }
    end

    context "with a collection that has a primary_language" do
      subject do
        described_class.create.tap do |col|
          col.primary_language = primary_language
        end
      end
      its(:primary_language) { is_expected.to eq 'English' }
    end
  end

  describe "#finding_aid_link" do
    subject { described_class.new }
    let(:finding_aid_link) { 'http://findingaid.edu' }

    context "with new collection" do
      its(:finding_aid_link) { is_expected.to be_falsey }
    end

    context "with a collection that has a finding_aid_link" do
      subject do
        described_class.create.tap do |col|
          col.finding_aid_link = finding_aid_link
        end
      end
      its(:finding_aid_link) { is_expected.to eq finding_aid_link }
    end
  end

  describe "#institution" do
    subject { described_class.new }
    let(:institution) { 'Emory University' }

    context "with new collection" do
      its(:institution) { is_expected.to be_falsey }
    end

    context "with a collection that has an institution" do
      subject do
        described_class.create.tap do |col|
          col.institution = institution
        end
      end
      its(:institution) { is_expected.to eq 'Emory University' }
    end
  end

  describe "#local_call_number" do
    subject { described_class.new }
    let(:local_call_number) { '123' }

    context "with new collection" do
      its(:local_call_number) { is_expected.to be_falsey }
    end

    context "with a collection that has a local_call_number" do
      subject do
        described_class.create.tap do |col|
          col.local_call_number = local_call_number
        end
      end
      its(:local_call_number) { is_expected.to eq '123' }
    end
  end

  describe "#keywords" do
    subject { described_class.new }
    let(:keywords) { ['Biology', 'Physics'] }

    context "with new collection" do
      its(:keywords) { is_expected.to be_empty }
    end

    context "with a collection that has keywords" do
      subject do
        described_class.create.tap do |col|
          col.keywords = keywords
        end
      end
      its(:keywords) { is_expected.to eq keywords }
    end
  end

  describe "#subject_topics" do
    subject { described_class.new }
    let(:subject_topics) { ['Religion'] }

    context "with new collection" do
      its(:subject_topics) { is_expected.to be_empty }
    end

    context "with a collection that has a subject_topics" do
      subject do
        described_class.create.tap do |col|
          col.subject_topics = subject_topics
        end
      end
      its(:subject_topics) { is_expected.to eq(['Religion']) }
    end
  end

  describe "#subject_names" do
    subject { described_class.new }
    let(:subject_names) { ['Example Name'] }

    context "with new collection" do
      its(:subject_names) { is_expected.to be_empty }
    end

    context "with a collection that has a subject_names" do
      subject do
        described_class.create.tap do |col|
          col.subject_names = subject_names
        end
      end
      its(:subject_names) { is_expected.to eq(['Example Name']) }
    end
  end

  describe "#subject_geo" do
    subject { described_class.new }
    let(:subject_geo) { ['United States'] }

    context "with new collection" do
      its(:subject_geo) { is_expected.to be_empty }
    end

    context "with a collection that has a subject_geo" do
      subject do
        described_class.create.tap do |col|
          col.subject_geo = subject_geo
        end
      end
      its(:subject_geo) { is_expected.to eq(['United States']) }
    end
  end

  describe "#subject_time_periods" do
    subject { described_class.new }
    let(:subject_time_periods) { ['Byzantine era (330–1453)'] }

    context "with new collection" do
      its(:subject_time_periods) { is_expected.to be_empty }
    end

    context "with a collection that has a subject_time_periods" do
      subject do
        described_class.create.tap do |col|
          col.subject_time_periods = subject_time_periods
        end
      end
      its(:subject_time_periods) { is_expected.to eq(['Byzantine era (330–1453)']) }
    end
  end

  describe "#notes" do
    subject { described_class.new }
    let(:notes) { ['general note'] }

    context "with new collection" do
      its(:notes) { is_expected.to be_empty }
    end

    context "with a collection that has notes" do
      subject do
        described_class.create.tap do |col|
          col.notes = notes
        end
      end
      its(:notes) { is_expected.to eq(['general note']) }
    end
  end

  describe "#rights_documentation" do
    subject { described_class.new }
    let(:rights_documentation) { 'Rights documentation uri' }

    context "with new collection" do
      its(:rights_documentation) { is_expected.to be_falsey }
    end

    context "with a collection that has rights_documentation" do
      subject do
        described_class.create.tap do |col|
          col.rights_documentation = rights_documentation
        end
      end
      its(:rights_documentation) { is_expected.to eq rights_documentation }
    end
  end

  describe "#sensitive_material" do
    subject { described_class.new }
    let(:sensitive_material) { 'supplemental material' }

    context "with new collection" do
      its(:sensitive_material) { is_expected.to be_falsey }
    end

    context "with a collection that has sensitive_material" do
      subject do
        described_class.create.tap do |col|
          col.sensitive_material = sensitive_material
        end
      end
      its(:sensitive_material) { is_expected.to eq sensitive_material }
    end
  end

  describe "#internal_rights_note" do
    subject { described_class.new }
    let(:internal_rights_note) { 'Internal review note' }

    context "with new collection" do
      its(:internal_rights_note) { is_expected.to be_falsey }
    end

    context "with a collection that has internal_rights_note" do
      subject do
        described_class.create.tap do |col|
          col.internal_rights_note = internal_rights_note
        end
      end
      its(:internal_rights_note) { is_expected.to eq internal_rights_note }
    end
  end

  describe "#contact_information" do
    subject { described_class.new }
    let(:contact_information) { 'Contact me at this email: example@example.com' }

    context "with new collection" do
      its(:contact_information) { is_expected.to be_falsey }
    end

    context "with a collection that has a contact_information" do
      subject do
        described_class.create.tap do |col|
          col.contact_information = contact_information
        end
      end
      its(:contact_information) { is_expected.to include 'Contact' }
    end
  end

  describe "#staff_notes" do
    subject { described_class.new }
    let(:staff_notes) { ['This is for internal staff use only'] }

    context "with new collection" do
      its(:staff_notes) { is_expected.to be_empty }
    end

    context "with a collection that has staff_notes" do
      subject do
        described_class.create.tap do |col|
          col.staff_notes = staff_notes
        end
      end
      its(:staff_notes) { is_expected.to eq staff_notes }
    end
  end

  describe "#system_of_record_ID" do
    subject { described_class.new }
    let(:system_of_record_ID) { 'Alma:123' }

    context "with new collection" do
      its(:system_of_record_ID) { is_expected.to be_falsey }
    end

    context "with a collection that has a system_of_record_ID" do
      subject do
        described_class.create.tap do |col|
          col.system_of_record_ID = system_of_record_ID
        end
      end
      its(:system_of_record_ID) { is_expected.to eq system_of_record_ID }
    end
  end

  describe "#emory_ark" do
    subject { described_class.new }
    let(:emory_ark) { ['Emory Legacy Ark'] }

    context "with new collection" do
      its(:emory_ark) { is_expected.to be_empty }
    end

    context "with a collection that has a emory_ark" do
      subject do
        described_class.create.tap do |col|
          col.emory_ark = emory_ark
        end
      end
      its(:emory_ark) { is_expected.to eq emory_ark }
    end
  end

  describe "#primary_repository_ID" do
    subject { described_class.new }
    let(:primary_repository_ID) { '123ABC' }

    context "with new collection" do
      its(:primary_repository_ID) { is_expected.to be_falsey }
    end

    context "with a collection that has a primary_repository_ID" do
      subject do
        described_class.create.tap do |col|
          col.primary_repository_ID = primary_repository_ID
        end
      end
      its(:primary_repository_ID) { is_expected.to eq primary_repository_ID }
    end
  end
end
