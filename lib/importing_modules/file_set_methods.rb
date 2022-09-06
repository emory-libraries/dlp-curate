# frozen_string_literal: true

module FileSetMethods
  def process_uploaded_file(work_permissions, file_set_attrs, ind, num_files)
    actor = ::Hyrax::Actors::FileSetActor.new(object, @user)

    @uploaded_file.update(file_set_uri: actor.file_set.uri)
    actor.file_set.permissions_attributes = work_permissions
    actor.create_metadata(@uploaded_file.fileset_use, file_set_attrs)
    actor.fileset_name(@uploaded_file.file.to_s) if @uploaded_file.file.present?
    create_content_for_actor(actor, @uploaded_file)
    if ind == num_files - 1
      @work.ordered_members << actor.file_set
      @work.save
    end
    actor.file_set.save
    actor.attach_to_work(@work)
  end

  def create_content_for_actor(actor, uploaded_file)
    actor.create_content(uploaded_file.preservation_master_file, @preferred, :preservation_master_file) if uploaded_file.preservation_master_file.present?
    actor.create_content(uploaded_file.intermediate_file, @preferred, :intermediate_file) if uploaded_file.intermediate_file.present?
    actor.create_content(uploaded_file.service_file, @preferred, :service_file) if uploaded_file.service_file.present?
    actor.create_content(uploaded_file.extracted_text, @preferred, :extracted) if uploaded_file.extracted_text.present?
    actor.create_content(uploaded_file.transcript, @preferred, :transcript_file) if uploaded_file.transcript.present?
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
    raw_strings = parser.file_sets.map { |v| v[:file_types] }&.compact
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
