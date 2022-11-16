# frozen_string_literal: true

class CompileFullTextJob < Hyrax::ApplicationJob
  def perform(work_id:, user_id:)
    work = CurateGenericWork.find(work_id)
    path = generate_full_text_data_file_from(work: work)
    file = File.open(path)
    user = User.find(user_id)
    file_set = FileSet.create(label: "Full Text Data - #{work_id}")
    actor = Hyrax::Actors::FileSetActor.new(file_set, user)
    actor.create_metadata(nil, {})
    actor.create_content(file, :transcript_file, :transcript_file)
    work.ordered_members << actor.file_set
    work.save
    actor.file_set.save
  end

  private

    def generate_full_text_data_file_from(work:)
      path = Rails.root.join('tmp', "full_text_data_#{work.id}")
      File.open(path, "wb+") { |f| f.puts("") }
      work.file_sets.map(&:transcript_file).compact.each do |transcript_file|
        next if transcript_file.content == "" || transcript_file.content == "[NO TEXT ON PAGE. This page does not contain any text recoverable by the OCR engine.]\n"

        File.open(path, "ab") do |f|
          f.puts(transcript_file.content)
        end
      end
      path
    end
end
