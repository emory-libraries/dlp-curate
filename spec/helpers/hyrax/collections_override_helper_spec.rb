# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyrax::CollectionsHelper do
  let(:user) { FactoryBot.create(:user, groups: ['admin']) }
  let(:ability) { Ability.new(user) }

  describe '#render_collection_links' do
    before do
      allow(controller).to receive(:current_ability).and_return(ability)
    end

    context 'when a GenericWork does not belongs to any collections', :clean_repo do
      let!(:work_doc) { SolrDocument.new(id: '123', title_tesim: ['My GenericWork']) }

      it 'renders nothing' do
        expect(helper.render_collection_links(work_doc)).to be_nil
      end
    end

    context 'when a GenericWork belongs to collections' do
      let(:coll_ids) { ['111', '222'] }
      let(:coll_titles) { ['Collection 111', 'Collection 222'] }
      let(:coll1_attrs) { { id: coll_ids[0], title_tesim: [coll_titles[0]] } }
      let(:coll2_attrs) { { id: coll_ids[1], title_tesim: [coll_titles[1]] } }
      let!(:work_doc) { SolrDocument.new(id: '123', title_tesim: ['My GenericWork'], member_of_collection_ids_ssim: coll_ids) }

      before do
        Hyrax::SolrService.add(coll1_attrs)
        Hyrax::SolrService.add(coll2_attrs)
        Hyrax::SolrService.commit
      end

      it 'renders a list of links to the collections' do
        expect(helper.render_collection_links(work_doc)).to match(/Is part of/i)
        expect(helper.render_collection_links(work_doc)).to match("href=\"/collections/#{coll_ids[0]}\"")
        expect(helper.render_collection_links(work_doc)).to match("href=\"/collections/#{coll_ids[1]}\"")
        expect(helper.render_collection_links(work_doc)).to match(coll_titles[0])
        expect(helper.render_collection_links(work_doc)).to match(coll_titles[1])
      end
    end

    context 'when a GenericWork belongs to deposit and source collections' do
      let(:coll_ids) { ['111', '222'] }
      let(:coll_titles) { ['Collection 111', 'Collection 222'] }
      let(:coll1_attrs) { { id: coll_ids[0], title_tesim: [coll_titles[0]], source_collection_id_tesim: coll_ids[1] } }
      let(:coll2_attrs) { { id: coll_ids[1], title_tesim: [coll_titles[1]] } }
      let!(:work_doc) { SolrDocument.new(id: '123', title_tesim: ['My GenericWork'], member_of_collection_ids_ssim: [coll_ids[0]], source_collection_id_tesim: coll_ids[1]) }

      before do
        Hyrax::SolrService.add(coll1_attrs)
        Hyrax::SolrService.add(coll2_attrs)
        Hyrax::SolrService.commit
      end

      it 'renders a list of links to the collections' do
        expect(helper.render_collection_links(work_doc)).to match(/Is part of/i)
        expect(helper.render_collection_links(work_doc)).to match("href=\"/collections/#{coll_ids[0]}\"")
        expect(helper.render_collection_links(work_doc)).to match("href=\"/collections/#{coll_ids[1]}\"")
        expect(helper.render_collection_links(work_doc)).to match(coll_titles[0])
        expect(helper.render_collection_links(work_doc)).to match(coll_titles[1])
      end
    end
  end
end
