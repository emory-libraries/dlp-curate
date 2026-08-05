# frozen_string_literal: true

# This module will be used to define persistent url
# for works and collections. Prefers emory_persistent_id (a locally
# minted NOID stored as a plain string) over the primary id.
module CuratePurl
  def purl
    persistent_id = if respond_to?(:emory_persistent_id) && emory_persistent_id.present?
                      emory_persistent_id
                    elsif respond_to?(:solr_document) && solr_document&.dig('emory_persistent_id_ssi').present?
                      solr_document&.dig('emory_persistent_id_ssi')
                    else
                      id
                    end
    "#{ENV['LUX_BASE_URL'] || 'localhost:3000'}/purl/#{persistent_id}"
  end
end
