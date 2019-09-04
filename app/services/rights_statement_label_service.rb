# frozen_string_literal: true

class RightsStatementLabelService
  include Singleton

  def label(uri:)
    Qa::Authorities::Local.subauthority_for('rights_statements').all.select { |t| t['id'] == uri }[0]['label']
  end
end
