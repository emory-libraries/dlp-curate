# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AwsFixityEvent, :clean, type: :model do
  let(:full_line) do
    { 'event_sha1': '3a1759f3e5591f0ef19c7ce67365f0a2dc6be076', 'event_bucket': 'fedora-cor-arch-binaries',
      'event_start': '2022-03-09 14:11:25', 'event_end': '2022-03-09 14:11:35',
      'event_type': 'AWS Fixity Check', 'initiating_user': 'AWS Fixity Tool',
      'outcome': 'Success', 'software_version': 'Serverless Fixity v1.*' }.with_indifferent_access
  end
  let(:empty_line) { {} }
  let(:full_line_object) { described_class.new(full_line) }
  let(:empty_line_object) { described_class.new(empty_line) }
  let(:full_line_results) do
    ["3a1759f3e5591f0ef19c7ce67365f0a2dc6be076", "fedora-cor-arch-binaries", "2022-03-09 14:11:25",
     "2022-03-09 14:11:35", "AWS Fixity Check", "AWS Fixity Tool", "Success",
     "Serverless Fixity v1.*", "intact"]
  end
  let(:empty_line_results) do
    [nil, nil, nil, nil, "Fixity Check", "AWS Serverless Fixity", nil, "Serverless Fixity v1.0",
     "check failed"]
  end
  let(:full_line_hash) do
    { "type" => "AWS Fixity Check", "start" => "2022-03-09 14:11:25", "end" => "2022-03-09 14:11:35",
      "details" => "Fixity intact for sha1:3a1759f3e5591f0ef19c7ce67365f0a2dc6be076 in fedora-cor-arch-binaries",
      "software_version" => "Serverless Fixity v1.*", "user" => "AWS Fixity Tool",
      "outcome" => "Success" }
  end
  let(:empty_line_hash) do
    { "type" => "Fixity Check", "start" => nil, "end" => nil, "details" => "Fixity check failed for sha1: in ",
      "software_version" => "Serverless Fixity v1.0", "user" => "AWS Serverless Fixity",
      "outcome" => nil }
  end

  describe '#new attributes' do
    context 'full line of attributes' do
      it 'contains the expected variables' do
        expect([full_line_object.sha1] + pull_non_reader_vars(full_line_object))
          .to match_array(full_line_results)
      end
    end

    context 'empty line of attributes' do
      it 'contains the expected variables' do
        expect([empty_line_object.sha1] + pull_non_reader_vars(empty_line_object))
          .to match_array(empty_line_results)
      end
    end
  end

  describe '#process_event' do
    context 'full line of attributes' do
      it 'returns the expected hash' do
        expect(full_line_object.process_event).to eq(full_line_hash)
      end
    end

    context ' empty line of attributes' do
      it 'returns the expected hash' do
        expect(empty_line_object.process_event).to eq(empty_line_hash)
      end
    end
  end

  def pull_non_reader_vars(obj)
    ['@aws_bucket', '@fixity_start', '@fixity_end', '@event_type', '@user', '@outcome',
     '@software_version', '@details_outcome'].map do |var|
      obj.instance_variable_get(var.to_sym)
    end
  end
end
