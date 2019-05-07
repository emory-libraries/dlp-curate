# monkey-patch Hydra::Works::AddFileToFileSet
require File.join(Gem::Specification.find_by_name("hydra-works").full_gem_path, "lib/hydra/works/services/add_file_to_file_set.rb")

module Hydra::Works
  class AddFileToFileSet
    class Updater
      def find_or_create_file_for_symbol(type, update_existing)
        association = file_set.association(type)
        raise ArgumentError, "you're attempting to add a file to a file_set using '#{type}' association but the file_set does not have an association called '#{type}''" unless association
        current_file = association.reader if update_existing
        if file_set.files.empty?
          current_file || association.build
        else
          file_set.files.build
          # This should take care of creating URIs for files within file_sets, however, establishing an association
          # might be tricky given that HydraWorks supports only one each of original_file, thumbnail, and extracted_text.
          # I guess we can use different types for files that are being attached after the first original_file by calling
          # AddTypeToFile PCDM class.
          # current_file = file_set.files.last
          # type= 'http://pcdm.org/use#PreservationMasterFile'
          # TODO: Pass a RDF URI as type to AddTypeToFile
          # Hydra::PCDM::AddTypeToFile.call(current_file, type_to_uri(type))
        end
      end
    end
  end
end
