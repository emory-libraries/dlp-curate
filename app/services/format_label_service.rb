# frozen_string_literal: true

class FormatLabelService
  include Singleton

  def label(uri:)
    Qa::Authorities::Local.subauthority_for('resource_types').all.find { |t| t['id'] == uri }['label']
  end
end
