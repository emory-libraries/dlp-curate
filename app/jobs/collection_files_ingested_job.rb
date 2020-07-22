# frozen_string_literal: true

class CollectionFilesIngestedJob < Hyrax::ApplicationJob
  def perform(collection_array = nil)
    collections = collection_array.present? ? selected_coll_hsh(collection_array) : collection_hsh

    collection_hashes = collections.map do |hsh|
      works = collection_works(hsh[:id])
      filesets = filesets(fileset_ids(works))

      { "collection_id" => hsh[:id], "collection_title" => hsh[:title]&.first,
        "work_total" => works.size, "fileset_total" => filesets.size,
        "file_total" => filesets_file_count(filesets) }
    end
    File.open(Rails.root.join('config', 'emory', "collection-counts-for-#{Time.current.strftime('%Y%m%dT%H%M')}.json"), "w") do |f|
      f.write(collection_hashes.to_json)
    end
  end

  private

    def solr_service
      Hyrax::SolrService
    end

    def query_builder
      Hyrax::SolrQueryBuilderService
    end

    def selected_coll_hsh(collection_array)
      collections = collection_array.map { |coll| Collection.find(coll) }
      collections.map { |c| { title: c.title, id: c.id } }
    end

    def collection_hsh
      Collection.all&.map { |c| { title: c.title, id: c.id } }
    end

    def collection_works(collection_id)
      solr_service.query(
        query_builder.construct_query(
          member_of_collection_ids_ssim: collection_id,
          has_model_ssim:                "CurateGenericWork"
        ), rows: 1_000_000
      )
    end

    def fileset_ids(works)
      works&.map { |w| w['file_set_ids_ssim'] }&.compact&.flatten
    end

    def filesets(ids)
      ids.map { |id| solr_service.query(query_builder.construct_query(id: id), rows: 1_000_000) }&.flatten
    end

    def filesets_file_count(filesets)
      filesets.sum { |fs| fs['sha1_tesim']&.compact&.uniq&.size }
    end
end
