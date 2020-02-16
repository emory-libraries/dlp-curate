# frozen_string_literal: true
require 'iiif_manifest'

class CreateManifest
  class << self
    def process(work_id = nil)
      if work_id.present?
        process_work(work_id)
      else
        CurateGenericWork.all.each do |work|
          process_work(work.id)
        end
      end
    end

    private

      def process_work(work_id)
        solr_doc = ::SolrDocument.find(work_id)
        date_modified = solr_doc[:date_modified_dtsi] || solr_doc[:system_create_dtsi]
        key = date_modified.to_datetime.strftime('%Y-%m-%d_%H-%M-%S') + '_' + solr_doc[:id]

        return if File.exist?(ENV['IIIF_MANIFEST_CACHE'] + key)
        presenter = Hyrax::CurateGenericWorkPresenter.new(solr_doc, ManifestAbility.new)
        manifest_hash = ::IIIFManifest::ManifestFactory.new(presenter).to_h
        persist_manifest(key: key, manifest_hash: manifest_hash)
      end

      def persist_manifest(key:, manifest_hash:)
        File.open(ENV['IIIF_MANIFEST_CACHE'] + key, 'w+') do |f|
          f.write(manifest_hash.to_json)
        end
      end
  end
end
