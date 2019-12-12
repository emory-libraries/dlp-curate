# frozen_string_literal: true

class LicensesLabelService
  include Singleton

  def label(uri:)
    Qa::Authorities::Local.subauthority_for('licenses').all.select { |t| t['id'] == uri }[0]['label']
  end
end
