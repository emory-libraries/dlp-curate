# frozen_string_literal: true
module IngestAssistiveMethods
  def process_uploaded_file(work_permissions, file_set_attrs)
    actor = ::Hyrax::Actors::FileSetActor.new(object, @user)

    @uploaded_file.add_file_set!(actor.file_set)
    actor.file_set.permissions_attributes = work_permissions
    actor.create_metadata(@uploaded_file.fileset_use, file_set_attrs)
    actor.fileset_name(@uploaded_file.file.to_s) if @uploaded_file.file.present?
    actor.file_set.save!
    CurateAfIngestJob.perform_later(actor.file_set, @uploaded_file, @user, @preferred)
    actor.attach_to_work(@work, file_set_attrs)
  end

  def preferred_file(uploaded_files)
    preferred = if uploaded_files.any? { |uf| uf&.service_file&.present? }
                  :service_file
                elsif uploaded_files.any? { |uf| uf&.intermediate_file&.present? }
                  :intermediate_file
                else
                  :preservation_master_file
                end
    preferred
  end

  def process_file_types(file_name)
    raw_strings = @object_factory.parser.file_sets.map { |v| v[:file_types] }&.compact
    split_strings = raw_strings.map { |rs| rs.split('|') }&.flatten
    string_type_hashes = process_string_type_hashes(split_strings)
    pulled_hash = string_type_hashes.select { |h| h[file_name].present? }&.first
    pulled_hash[file_name] || "preservation_master_file"
  end

  def process_string_type_hashes(split_strings)
    split_strings.map do |ss|
      pieces = ss.split(':')
      { pieces[0].to_s => pieces[1] }
    end
  end
end
