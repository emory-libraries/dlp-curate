# frozen_string_literal: true

class CompileFullTextJob < Hyrax::ApplicationJob
  def perform(work_id:, user_id:)
    path = generate_full_text_data_file(work_id: work_id)
    file = File.open(path)
    user = User.find(user_id)
    actor = Hyrax::Actors::FileSetActor.new(FileSet.create, user)
    actor.create_content(file, preferred, :transcript_file)
  end

  private

    def generate_full_text_data_file(work_id:)
      work = CurateGenericWork.find(work_id)
      path = Rails.root.join('tmp', 'full_text_data_files', "full_text_data_#{work_id}")
      File.open(path, "w+") { |f| f.write("Full Text Data - Work ID: #{work_id}") }
      work.file_sets.map(&:transcript_file).compact.each do |transcript_file|
        next if transcript_file.content == "" || transcript_file.content == "[NO TEXT ON PAGE. This page does not contain any text recoverable by the OCR engine.]\n"

        File.open(path, "a") do |f|
          f.puts(transcript_file.content)
        end
      end
      path
    end
end
