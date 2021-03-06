# frozen_string_literal: true

# This class gets called by ActiveFedora::IndexingService#olrize_rdf_assertions
class CurateIndexer < ActiveFedora::RDF::IndexingService
  class_attribute :stored_and_facetable_fields, :stored_fields, :symbol_fields
  self.stored_and_facetable_fields = %i[creator contributors holding_repository primary_language subject_topics subject_names subject_geo]
  self.stored_fields = %i[abstract administrative_unit abstract institution
                          local_call_number keywords subject_time_periods notes sensitive_material
                          internal_rights_note contact_information staff_notes system_of_record_ID
                          emory_ark primary_repository_ID]
  # self.symbol_fields = %i[import_url]

  private

    # This method overrides ActiveFedora::RDF::IndexingService
    # @return [ActiveFedora::Indexing::Map]
    def index_config
      merge_config(
        merge_config(super, stored_and_facetable_index_config),
        stored_searchable_index_config
      )
    end

    # This can be replaced by a simple merge once
    # https://github.com/samvera/active_fedora/pull/1227
    # is available to us
    # @param [ActiveFedora::Indexing::Map] first
    # @param [Hash] second
    def merge_config(first, second)
      first_hash = first.instance_variable_get(:@hash).deep_dup
      ActiveFedora::Indexing::Map.new(first_hash.merge(second))
    end

    def stored_and_facetable_index_config
      stored_and_facetable_fields.each_with_object({}) do |name, hash|
        hash[name] = index_object_for(name, as: [:stored_searchable, :facetable])
      end
    end

    def stored_searchable_index_config
      stored_fields.each_with_object({}) do |name, hash|
        hash[name] = index_object_for(name, as: [:stored_searchable])
      end
    end

    def index_object_for(attribute_name, as: [])
      ActiveFedora::Indexing::Map::IndexObject.new(attribute_name) do |idx|
        idx.as(*as)
      end
    end
end
