# frozen_string_literal: true

class LicensesLabelService
  include Singleton

  def label(uri:)
    Qa::Authorities::Local.subauthority_for('licenses').all.find { |t| t['id'] == uri }['label']
  end
end
