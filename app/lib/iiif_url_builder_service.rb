# frozen_string_literal: true

# Builds IIIF image/info URLs for file sets.
# Supports both AF FileSet and Valkyrie FileSetResource during lazy migration.
class IiifUrlBuilderService
  attr_accessor :file_set_id, :file_set, :size

  def initialize(file_set_id:, size:)
    @file_set_id = file_set_id
    @file_set = find_file_set
    @size = size
  end

  def sha1
    sha1_with_urn = extract_sha1_checksum || 'urn:sha1:unknown'
    sha1_with_urn.gsub('urn:sha1:', '')
  end

  def sha1_url
    ENV['IIIF_SERVER_URL'] + sha1 + '/full/' + size + '/0/default.jpg'
  end

  def sha1_info_url
    ENV['IIIF_SERVER_URL'] + sha1
  end

  def file_id_info_url
    ENV['IIIF_SERVER_URL'] + file_set_id.gsub('/', '%2F')
  end

  def file_set_id_url
    ENV['IIIF_SERVER_URL'] + file_set.id.to_s + '/full/' + size + '/0/default.jpg'
  end

  def file_set_id_base
    file_set_id.gsub('/', '%2F').split('%2F').fetch(0, file_set_id)
  end

  private

    def find_file_set
      if Hyrax.config.valkyrie_transition?
        Hyrax.query_service.find_by(id: file_set_id_base)
      else
        FileSet.find(file_set_id_base)
      end
    rescue Hyrax::ObjectNotFoundError, Valkyrie::Persistence::ObjectNotFoundError
      nil
    end

    def extract_sha1_checksum
      return nil unless file_set

      case file_set
      when Hyrax::Resource
        extract_valkyrie_sha1
      else
        file_set.send(file_set.preferred_file)&.checksum&.value
      end
    end

    PREFERRED_USE_ORDER = [
      Hyrax::FileMetadata::Use::SERVICE_FILE,
      Hyrax::FileMetadata::Use::INTERMEDIATE_FILE,
      Hyrax::FileMetadata::Use::ORIGINAL_FILE
    ].freeze

    def extract_valkyrie_sha1
      file_metadata = preferred_file_metadata
      return nil unless file_metadata

      checksums = Array(file_metadata.original_checksum)
      checksums.find { |c| c.to_s.start_with?('urn:sha1:') }
    end

    def preferred_file_metadata
      PREFERRED_USE_ORDER.each do |use|
        fm = Hyrax.custom_queries
                  .find_many_file_metadata_by_use(resource: file_set, use:)
                  .first
        return fm if fm
      end
      nil
    end
end
