# frozen_string_literal: true

class FormatLabelService
  include Singleton

  def label(uri:)
    Qa::Authorities::Local.subauthority_for('resource_types').all.select { |t| t['id'] == uri }[0]['label']
  end
end
