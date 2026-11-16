# frozen_string_literal: true

class CompileFullTextJob < Hyrax::ApplicationJob
  def perform(work_id:, user_id:)
    work = find_work(work_id)
    path = generate_full_text_data_file_from!(work:)
    user = User.find(user_id)
    generate_file_set_from(path:, work:, user:)
  end

  private

    def find_work(work_id)
      if Hyrax.config.valkyrie_transition?
        Hyrax.query_service.find_by(id: work_id)
      else
        CurateGenericWork.find(work_id)
      end
    end

    def generate_full_text_data_file_from!(work:)
      path = Rails.root.join('tmp', "full_text_data_#{work.id}.txt")
      File.open(path, "wb+") { |f| f.puts("") }

      map = get_transcript_files(work:)
      ordered_page_keys = map.keys.sort_by { |key| key.partition(' ').last.to_i }

      ordered_page_keys.each do |key|
        content = map[key]
        next if content == "" || content == "[NO TEXT ON PAGE. This page does not contain any text recoverable by the OCR engine.]\n"
        File.open(path, "ab") do |f|
          f.puts(content&.encode('UTF-8', invalid: :replace, undef: :replace, replace: ''))
        end
      end

      path
    end

    def get_transcript_files(work:)
      member_ids = work.member_ids
      map = {}

      member_ids.each do |member_id|
        file_set = find_file_set(member_id)
        next unless file_set.title&.first&.starts_with?('Page')

        transcript_content = transcript_content_for(file_set)
        next if transcript_content.blank?

        label = file_set.is_a?(Hyrax::Resource) ? Array(file_set.label).first : file_set.label
        map[label] = transcript_content
      end
      map
    end

    def find_file_set(member_id)
      if Hyrax.config.valkyrie_transition?
        Hyrax.query_service.find_by(id: member_id)
      else
        FileSet.find(member_id)
      end
    end

    def transcript_content_for(file_set)
      case file_set
      when Hyrax::Resource
        valkyrie_transcript_content(file_set)
      else
        file_set.pulled_transcript_file&.content
      end
    end

    def valkyrie_transcript_content(file_set)
      fm = Hyrax.custom_queries.find_many_file_metadata_by_use(
        resource: file_set, use: Hyrax::FileMetadata::Use::TRANSCRIPT
      ).first
      return unless fm&.file_identifier

      file = Hyrax.storage_adapter.find_by(id: fm.file_identifier)
      file&.read
    rescue Valkyrie::StorageAdapter::FileNotFound
      nil
    end

    def generate_file_set_from(path:, work:, user:)
      file = File.open(path)
      sanitized_file = CarrierWave::SanitizedFile.new(file)
      uploaded_file = Hyrax::UploadedFile.create(user:,
                                                 preservation_master_file: sanitized_file,
                                                 file:                     "Full Text Data - #{work.id}",
                                                 fileset_use:              'Primary Content')
      AttachFilesToWorkJob.perform_later(work, [uploaded_file])
      file.close
      File.delete(path) if File.exist?(path)
    end
end
