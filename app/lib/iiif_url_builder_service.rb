# frozen_string_literal: true

# Builds IIIF image/info URLs for file sets.
# Supports both AF FileSet and Valkyrie FileSetResource during lazy migration.
class IiifUrlBuilderService
  include PullResourceOrAfObj
  attr_accessor :file_set_id, :file_set, :size

  def initialize(file_set_id:, size:)
    @file_set_id = file_set_id
    @file_set = find_file_set
    @size = size
  end

  def iiif_url
    case file_set
    when FileSetResource
      file_set_id_url
    else
      sha1_url
    end
  end

  def info_url
    case file_set
    when FileSetResource
      file_id_info_url
    else
      sha1_info_url
    end
  end

  def sha1_url
    ENV['IIIF_SERVER_URL'] + sha1 + '/full/' + size + '/0/default.jpg'
  end

  def file_set_id_url
    ENV['IIIF_SERVER_URL'] + "fedora7--#{resolved_identifier_endpath}--#{file_set.id}" + '/full/' + size + '/0/default.jpg'
  end

  def sha1_info_url
    ENV['IIIF_SERVER_URL'] + sha1
  end

  def file_id_info_url
    ENV['IIIF_SERVER_URL'] + file_set.id.to_s.gsub('/', '%2F')
  end

  def sha1
    sha1_with_urn = extract_sha1_checksum || 'urn:sha1:unknown'
    sha1_with_urn.gsub('urn:sha1:', '')
  end

  def file_set_id_base
    file_set_id.to_s.gsub('/', '%2F').split('%2F').fetch(0, file_set_id)
  end

  private

    def find_file_set
      obj = pull_object_based_on_id(id: file_set_id_base)

      return Hyrax.query_service.find_by(id: obj.file_set_id) if obj.is_a?(Hyrax::FileMetadata)
      obj
    rescue IneligibleIdError
      nil
    end

    # For Valkyrie works, ManifestBuilderService passes the preferred file's
    # FileMetadata id rather than the FileSet id, so the lookup may return a
    # Hyrax::FileMetadata (which is not a Hyrax::Resource).
    def extract_sha1_checksum
      return nil unless file_set
      file_set.send(file_set.preferred_file)&.checksum&.value
    end

    def resolved_identifier_endpath
      case file_set.preferred_file
      when :preservation_master_file
        'original'
      else
        file_set.preferred_file.to_s.sub('_file', '')
      end
    end
end
