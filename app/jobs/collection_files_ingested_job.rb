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

    def selected_coll_hsh(collection_array)
      collections = collection_array.map { |coll| find_collection(coll) }
      collections_hasherizer(collections)
    end

    # Change below was necessary to institute Source/Deposit Collection structure.
    # For more information, read the SOURCE_DEPOSIT_CHANGES_README.md in dlp-curate's root folder.
    def collection_hsh
      collections_hasherizer(source_collections)
    end

    # Change below was necessary to institute Source/Deposit Collection structure.
    # For more information, read the SOURCE_DEPOSIT_CHANGES_README.md in dlp-curate's root folder.
    def collection_works(collection_id)
      Collection.related_works_solrized(collection_id)
    end

    def fileset_ids(works)
      works&.map { |w| w['file_set_ids_ssim'] }&.compact&.flatten
    end

    def filesets(ids)
      ids.map do |id|
        Hyrax::SolrService.query(
          Hyrax::SolrQueryBuilderService.construct_query(id:),
          rows: 1_000_000
        )
      end&.flatten
    end

    def filesets_file_count(filesets)
      filesets.sum { |fs| fs['sha1_tesim']&.compact&.uniq&.size || 0 }
    end

    def find_collection(id)
      if Hyrax.config.valkyrie_transition?
        Hyrax.query_service.find_by(id:)
      else
        Collection.find(id)
      end
    end

    # Change below was necessary to institute Source/Deposit Collection structure.
    # For more information, read the SOURCE_DEPOSIT_CHANGES_README.md in dlp-curate's root folder.
    def source_collections
      collection_docs = Hyrax::SolrService.query("has_model_ssim:Collection", rows: 1_000_000, fl: "id")
      collection_docs.filter_map do |doc|
        col = find_collection(doc["id"])
        col unless Hyrax::CollectionType&.for(collection: col)&.deposit_only_collection?
      end
    end

    def collections_hasherizer(collection_array)
      collection_array&.map { |c| { title: c.title, id: c.id } }
    end
end
