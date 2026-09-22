# frozen_string_literal: true

# Dual-path helpers so the IIIF manifest pipeline can load both ActiveFedora
# objects and Valkyrie resources during Hyrax valkyrie_transition.
module ManifestValkyrieCompat
  class << self
    def find_work(id)
      id = id.to_s
      return CurateGenericWork.find(id) unless valkyrie_transition?

      Hyrax.query_service.find_by(id:)
    rescue Valkyrie::Persistence::ObjectNotFoundError, Hyrax::ObjectNotFoundError, Ldp::BadRequest, Ldp::HttpError, Faraday::Error
      CurateGenericWork.find(id)
    end

    def find_file_set(id)
      id = id.to_s
      return FileSet.find(id) unless valkyrie_transition?

      Hyrax.query_service.find_by(id:)
    rescue Valkyrie::Persistence::ObjectNotFoundError, Hyrax::ObjectNotFoundError, Ldp::BadRequest, Ldp::HttpError, Faraday::Error
      FileSet.find(id)
    end

    def file_set_member_ids(curation_concern)
      if valkyrie_resource?(curation_concern)
        member_ids = Array(curation_concern.member_ids).map { |member_id| member_id.to_s.presence }.compact
        return member_ids if member_ids.empty?

        member_ids - child_work_ids_for(curation_concern)
      else
        curation_concern.ordered_member_ids - curation_concern.child_work_ids
      end
    end

    def file_set_mime_type(file_set)
      return file_set.mime_type unless valkyrie_resource?(file_set)

      preferred_file(file_set)&.mime_type || file_set.try(:mime_type)
    end

    def file_set_visibility(file_set)
      return file_set.visibility unless valkyrie_resource?(file_set)

      Hyrax::VisibilityReader.new(resource: file_set).read
    end

    def file_set_dimensions(file_set)
      original = file_set.original_file
      return [original&.width, original&.height] unless valkyrie_resource?(file_set)

      [Array(original&.width).first, Array(original&.height).first]
    end

    def preferred_file(file_set)
      return unless file_set
      return file_set.original_file if valkyrie_resource?(file_set)
      return unless file_set.respond_to?(:preferred_file)

      preferred = file_set.preferred_file
      return unless preferred

      file_set.send("pulled_#{preferred}".to_sym)
    end

    def preferred_file_id(file_set)
      return file_set.id.to_s if valkyrie_resource?(file_set)

      file = preferred_file(file_set)
      file ? file.id : file_set.id
    end

    def checksum_urn(file_set)
      extract_checksum(preferred_file(file_set)).presence || 'urn:sha1:unknown'
    end

    def valkyrie_transition?
      Hyrax.config.valkyrie_transition?
    end

    def valkyrie_resource?(object)
      object.is_a?(Valkyrie::Resource)
    end

    private

      def child_work_ids_for(resource)
        Hyrax.custom_queries.find_child_work_ids(resource:).map(&:to_s)
      end

      def extract_checksum(file)
        return unless file

        checksum = file.try(:checksum)
        return unless checksum

        item = checksum.respond_to?(:first) ? checksum.first : checksum
        return unless item
        return item.value if item.respond_to?(:value)
        return item.uri.to_s if item.respond_to?(:uri)

        item.to_s
      end
  end
end
