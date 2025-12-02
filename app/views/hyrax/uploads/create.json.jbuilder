# frozen_string_literal: true
# [Hyrax-overwrite-hyrax-v5.2.0] removes `size` key/value and uses our preferred `name` value logic.

json.files [@upload] do |uploaded_file|
  json.id uploaded_file.id
  json.name uploaded_file.collection_banner.file.filename if uploaded_file.collection_banner.file.present?
  # TODO: implement these
  # json.url  "/uploads/#{uploaded_file.id}"
  # json.thumbnail_url uploaded_file.id
  json.deleteUrl hyrax.uploaded_file_path(uploaded_file)
  json.deleteType 'DELETE'
end
