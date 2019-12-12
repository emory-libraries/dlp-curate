# frozen_string_literal: true

class ClambyScanner < Hydra::Works::VirusScanner
  def infected?
    result = Clamby.virus?(file)
    Rails.logger.error "Virus encountered while processing file #{file.to_s.split('/').last}" if result
    result
  end
end
