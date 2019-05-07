class AttachFilesToFileSetJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  def perform(work, file_set, uploaded_file, type)
    validate_file!(uploaded_file)
    depositor = proxy_or_depositor(work)
    user = User.find_by_user_key(depositor)

    actor = Hyrax::Actors::FilesActor.new(file_set, user)
    actor.create_content(uploaded_file, type)

    # TODO: Convert type symbol to RDF URI
  end

  private

    def validate_file!(uploaded_file)
      return true if uploaded_file.is_a? Hyrax::UploadedFile
      raise ArgumentError, "Hyrax::UploadedFile required, but #{uploaded_file.class} received: #{uploaded_file.inspect}"
    end

    ##
    # A work with files attached by a proxy user will set the depositor as the intended user
    # that the proxy was depositing on behalf of. See tickets #2764, #2902.
    def proxy_or_depositor(work)
      work.on_behalf_of.blank? ? work.depositor : work.on_behalf_of
    end
end
