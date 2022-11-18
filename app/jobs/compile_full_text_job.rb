# frozen_string_literal: true

class CompileFullTextJob < Hyrax::ApplicationJob
  def perform(work_id:, user_id:)
    work = CurateGenericWork.find(work_id)

    begin
      path = generate_full_text_data_file_from!(work: work)
    rescue => e
      Rails.logger.error("Unable to generate full text data for work #{work_id} due to the following error: #{e.message}")
    end

    file = File.open(path)
    user = User.find(user_id)
    generate_file_set_from(file: file, work: work, user: user)
  end

  private

    def generate_full_text_data_file_from!(work:)
      path = Rails.root.join('tmp', "full_text_data_#{work.id}.txt")
      File.open(path, "wb+") { |f| f.puts("") }
      file_sets = CurateGenericWork.last.file_sets.filter { |fs| fs.label&.starts_with?('Page') }
      file_sets = file_sets.sort_by { |fs| fs.label.partition(' ').last.to_i }
      file_sets.map(&:transcript_file).compact.each do |transcript_file|
        next if transcript_file.content == "" || transcript_file.content == "[NO TEXT ON PAGE. This page does not contain any text recoverable by the OCR engine.]\n"

        File.open(path, "ab") do |f|
          f.puts(transcript_file.content)
        end
      end
      path
    end

    def generate_file_set_from(file:, work:, user:)
      file_set = FileSet.create(label: "Full Text Data - #{work.id}")
      actor = Hyrax::Actors::FileSetActor.new(file_set, user)
      actor.create_metadata(nil, {})
      actor.create_content(file, :transcript_file, :transcript_file)
      work.ordered_members << actor.file_set
      work.save
      actor.file_set.save
    end
end
