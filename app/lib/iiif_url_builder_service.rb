# frozen_string_literal: true

class IiifUrlBuilderService
  attr_accessor :file_set_id, :file_set, :size

  def initialize(file_set_id:, size:)
    @file_set_id = file_set_id
    @file_set = begin FileSet.find(file_set_id_base)
                rescue ActiveFedora::ObjectNotFoundError
                  nil
                end
    @size = size
  end

  def sha1
    sha1_with_urn = file_set&.send(file_set.preferred_file)&.checksum&.value || 'urn:sha1:unknown'
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
    ENV['IIIF_SERVER_URL'] + file_set.id + '/full/' + size + '/0/default.jpg'
  end

  def file_set_id_base
    file_set_id.gsub('/', '%2F').split('%2F').fetch(0, file_set_id)
  end
end
