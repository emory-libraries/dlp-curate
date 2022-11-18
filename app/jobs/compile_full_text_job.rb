# frozen_string_literal: true

class CompileFullTextJob < Hyrax::ApplicationJob
  def perform(work_id:, user_id:)
    work = CurateGenericWork.find(work_id)
    path = generate_full_text_data_file_from!(work: work)
    user = User.find(user_id)
    generate_file_set_from(path: path, work: work, user: user)
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

    def generate_file_set_from(path:, work:, user:)
      file = File.open(path)
      label = "Full Text Data - #{work.id}"
      file_set = FileSet.create(label: label, title: [label])
      io_wrapper = JobIoWrapper.create_with_varied_file_handling!(user: user, file: file, relation: :transcript_file, file_set: file_set, preferred: :transcript_file)
      IngestJob.new.perform(io_wrapper)
      work.ordered_members << file_set
      work.save
      file_set.save
      File.delete(path) if File.exist?(path)
    end
end
