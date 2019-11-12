module Curate
  class FileSetIndexer < Hyrax::FileSetIndexer
    def generate_solr_document
      super.tap do |solr_doc|
        solr_doc['pcdm_use_tesim'] = object.pcdm_use if object.pcdm_use.present?
        solr_doc['file_path_ssim'] = object.file_path if object.file_path.present?
        solr_doc['creating_application_name_ssim'] = object.creating_application_name if object.creating_application_name.present?
        solr_doc['puid_ssim'] = object.puid if object.puid.present?
        solr_doc['date_modified_ssim'] = object.date_modified if object.date_modified.present?
        if object.preservation_master_file.present?
          solr_doc['file_name_ssim'] = object.preservation_master_file.file_name
          solr_doc['file_size_ssim'] = object.preservation_master_file.file_size
          solr_doc['date_created_ssim'] = object.preservation_master_file.date_created
          solr_doc['valid_ssim'] = object.preservation_master_file.valid
          solr_doc['well_formed_ssim'] = object.preservation_master_file.well_formed
          solr_doc['character_set_ssim'] = object.preservation_master_file.character_set
          solr_doc['byte_order_ssim'] = object.preservation_master_file.byte_order
          solr_doc['color_space_ssim'] = object.preservation_master_file.color_space
          solr_doc['compression_ssim'] = object.preservation_master_file.compression
          solr_doc['profile_name_ssim'] = object.preservation_master_file.profile_name
          solr_doc['profile_version_ssim'] = object.preservation_master_file.profile_version
        end
      end
    end
  end
end
