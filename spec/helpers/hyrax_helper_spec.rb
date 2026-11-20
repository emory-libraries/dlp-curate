# frozen_string_literal: true
require 'rails_helper'

RSpec.describe HyraxHelper, type: :helper do
  describe '#available_user_groups' do
    let(:ability) { instance_double(Ability, admin?: admin, user_groups: ['public', 'registered', 'rose_viewer']) }

    before do
      ['rose_manager', 'rose_viewer', 'admin'].each { |name| Role.find_or_create_by!(name:) }
    end

    context 'for an admin' do
      let(:admin) { true }

      it 'offers every role managed at /roles, sorted' do
        expect(helper.available_user_groups(ability:)).to include('admin', 'rose_manager', 'rose_viewer')
        expect(helper.available_user_groups(ability:)).to eq helper.available_user_groups(ability:).sort
      end

      it 'still offers the role map groups, once' do
        allow(::User.group_service).to receive(:role_names).and_return(['admin', 'role_map_group'])

        expect(helper.available_user_groups(ability:)).to include('role_map_group')
        expect(helper.available_user_groups(ability:).count('admin')).to eq 1
      end
    end

    context 'for a non-admin' do
      let(:admin) { false }

      it "offers the user's own groups, as Hyrax does" do
        expect(helper.available_user_groups(ability:)).to eq ['public', 'registered', 'rose_viewer']
      end
    end
  end
end
