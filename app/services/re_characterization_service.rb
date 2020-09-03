# frozen_string_literal: true

class ReCharacterizationService
  def initialize(repository_file)
    @repository_file = repository_file
  end

  def empty_characterization
    characterization_setters.each { |term| @repository_file.send("#{term}=", []) }
    @repository_file.save!
  end

  def self.empty_out_characterization(repository_file)
    service = ReCharacterizationService.new(repository_file)
    service.empty_characterization
  end

  private

    def characterization_terms
      Hydra::Works::Characterization::FitsDocument.terminology.terms.keys
    end

    def characterization_setters
      characterization_terms.select { |term| @repository_file.respond_to?("#{term}=") }
    end
end
