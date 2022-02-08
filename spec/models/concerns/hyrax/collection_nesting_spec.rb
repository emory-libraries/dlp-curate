# frozen_string_literal: true
# [Hyrax-overwrite-v3.1.0] Changing reindex-extent to limited instead of full in order
# to speed up collection indexing.
require 'rails_helper'
require 'shoulda/callback/matchers'

RSpec.describe Hyrax::CollectionNesting do
  describe 'including this module' do
    subject :collection do
      klass.new.tap { |obj| obj.id = collection.id }
    end

    let(:klass) do
      Class.new do
        extend ActiveModel::Callbacks
        include ActiveModel::Validations::Callbacks
        # Because we need these declared before we include the Hyrax::CollectionNesting
        define_model_callbacks :destroy, only: :after
        define_model_callbacks :save, only: :after
        define_model_callbacks :save, only: :before

        def destroy
          true
        end

        def update_index
          true
        end

        def before_save
          false
        end

        def after_save
          true
        end
        include Hyrax::CollectionNesting

        attr_accessor :id
      end
    end

    let(:user) { FactoryBot.create(:user) }
    let!(:collection) { FactoryBot.create(:collection_lw, collection_type_settings: [:nestable]) }
    let!(:child_collection) { FactoryBot.create(:collection_lw, collection_type_settings: [:nestable]) }
    let(:extent) { Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX }

    before do
      Hyrax::Collections::NestedCollectionPersistenceService.persist_nested_collection_for(parent: collection, child: child_collection)
    end

    it { is_expected.to callback(:update_nested_collection_relationship_indices).after(:update_index) }
    it { is_expected.to callback(:update_child_nested_collection_relationship_indices).after(:destroy) }
    it { is_expected.to callback(:before_update_nested_collection_relationship_indices).before(:save) }
    it { is_expected.to callback(:after_update_nested_collection_relationship_indices).after(:save) }
    it { is_expected.to respond_to(:update_nested_collection_relationship_indices) }
    it { is_expected.to respond_to(:update_child_nested_collection_relationship_indices) }
    it { is_expected.to respond_to(:use_nested_reindexing?) }
    it { is_expected.to respond_to(:reindex_extent) }
    it { is_expected.to respond_to(:reindex_extent=) }

    context 'after_update_index callback' do
      describe '#update_nested_collection_relationship_indices' do
        it 'will call Hyrax.config.nested_relationship_reindexer' do
          expect(Hyrax.config.nested_relationship_reindexer).to receive(:call).with(id: collection.id, extent: extent).and_call_original
          collection.update_nested_collection_relationship_indices
        end

        it 'will not call during save' do
          allow(klass).to receive(:before_save).and_return(true)
          expect(Hyrax.config.nested_relationship_reindexer).not_to receive(:call)
        end
      end
    end

    context 'after_destroy callback', with_nested_reindexing: true do
      describe '#update_child_nested_collection_relationship_indices' do
        it 'will call Hyrax.config.nested_relationship_reindexer' do
          expect(Hyrax.config.nested_relationship_reindexer).to receive(:call).with(id: child_collection.id, extent: extent).and_call_original
          collection.update_child_nested_collection_relationship_indices
        end
      end

      describe '#find_children_of' do
        it 'will return an array containing the child collection ids' do
          expect(collection.find_children_of(destroyed_id: collection.id).first.id).to eq(child_collection.id)
        end
      end
    end
  end
end
