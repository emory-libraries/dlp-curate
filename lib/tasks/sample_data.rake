# frozen_string_literal: true
namespace :dce do
  desc "Load initial sample data"
  task load_sample_data: :environment do
    load_sample_data
    puts "Loaded sample data"
  end
end

def load_sample_data
  load_first_object
end

def load_first_object
  work = CurateGenericWork.new
  work.legacy_identifier = ["dams:179629", "MSS1218_B011_I052"]
  work.abstract = "Fake Abstract"
  work.administrative_unit = "Stuart A. Rose Manuscript, Archives and Rare Book Library"
  work.local_call_number = "MSS 1218"
  work.contact_information = "Fake contact information"
  work.creator = ["Fake Creator"]
  work.date_created = "XXXX"
  work.date_issued = "XXXX"
  work.content_genre = ["card photographs (photographs)"]
  work.holding_repository = "Stuart A. Rose Manuscript, Archives and Rare Book Library"
  work.institution = "Emory University"
  work.primary_language = "Fake Primary Language"
  work.note = ["Fake Note"]
  work.legacy_ark = ["Fake Legacy Ark"]
  work.place_of_production = "Fake Place of Production"
  work.publisher = "Fake Publisher"
  work.rights_statement = ["Emory University does not control copyright for this image.Â¬â€ This image is made available for individual viewing and reference for educational purposes only such as personal study, preparation for teaching, and research.Â¬â€ Your reproduction, distribution, public display or other re-use of any content beyond a fair use as codified in section 107 of US Copyright Law is at your own risk.Â¬â€ We are always interested in learning more about our collections.Â¬â€ If you have information regarding this photograph, please contact marbl@emory.edu."]
  work.rights_statement_controlled = "In Copyright"
  work.subject_names = ["Fake Subject Name 1", "Fake Subject Name 2"]
  work.subject_geo = ["Fake Subject Geo 1", "Fake Subject Geo 2"]
  work.keywords = ["Education: Elementary and Secondary"]
  work.subject_topics = ["Classrooms.", "Tables.", "Blackboards.", "Furnaces.", "Students.", "Chairs.", "Coats."]
  work.uniform_title = "Fake Uniform Title"
  work.table_of_contents = "Fake TOC"
  work.title = ["Students sitting on floor, chairs and tables in classroom with furnace"]
  work.content_type = "still image"
  work.data_classification = ["Confidential"]
  work.visibility = "open"
  work.legacy_rights = "Emory University does not control copyright for this image. This image is made available for individual viewing and reference for educational purposes only such as personal study, preparation for teaching, and research. Your reproduction, distribution, public display or other re-use of any content beyond a fair use as codified in section 107 of US Copyright Law is at your own risk. We are always interested in learning more about our collections. If you have information regarding this photograph, please contact marbl@emory.edu."
  work.date_digitized = "Fake Date Digitized"
  work.transfer_engineer = "Fake Transfer Engineer"
  work.save
end
