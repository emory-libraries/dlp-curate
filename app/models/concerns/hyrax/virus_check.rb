module Hyrax
  module VirusCheck
    extend ActiveSupport::Concern

    included do
      validate :must_not_detect_viruses

      def viruses?
        return false unless original_file&.new_record? # We have a new file to check
        VirusCheckerService.file_has_virus?(original_file)
      end

      def must_not_detect_viruses
        event_start = DateTime.current
        event = { 'type' => 'Virus Check', 'start' => event_start, 'outcome' => 'Success', 'details' => 'No viruses were found', 'software_version' => 'Curate v.1',
                  'user' => user.uid }
        create_preservation_event(file_set, event) unless viruses?
        return true unless viruses?
        errors.add(:base, "Failed to verify uploaded file is not a virus")
        false
      end
    end
  end
end
