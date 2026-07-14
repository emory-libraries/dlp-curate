# frozen_string_literal: true

class RightsStatementLabelService
  include Singleton

  def label(uri:)
    Qa::Authorities::Local.subauthority_for('rights_statements').all.find { |t| t['id'] == uri }['label']
  end
end
