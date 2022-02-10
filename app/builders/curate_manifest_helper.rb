# frozen_string_literal: true
class CurateManifestHelper
  include Rails.application.routes.url_helpers
  include ActionDispatch::Routing::PolymorphicRoutes

  # Build a rendering hash (logic and method taken from Hyrax-v3.1.0, except host resolution)
  #
  # @return [Hash] rendering
  def build_rendering(file_set_id)
    file_set_document = query_for_rendering(file_set_id)
    label = file_set_document.label.present? ? ": #{file_set_document.label}" : ''
    mime = file_set_document.mime_type.presence || I18n.t("hyrax.manifest.unknown_mime_text")
    {
      '@id' => Hyrax::Engine.routes.url_helpers.download_url(file_set_document.id, host: "http://#{ENV['HOSTNAME'] || 'localhost:3000'}"),
      'format' => mime,
      'label' => I18n.t("hyrax.manifest.download_text") + label
    }
  end

  # Query for the properties to create a rendering
  #
  # @return [SolrDocument] query result
  def query_for_rendering(file_set_id)
    ::SolrDocument.find(file_set_id)
  end
end
