# frozen_string_literal: true

namespace :dce do
  desc "Load initial sample data"
  task load_sample_data: :environment do
    Rake::Task["hyrax:default_admin_set:create"].invoke
    Rake::Task["hyrax:default_collection_types:create"].invoke
    load_sample_data
    puts "Loaded sample data"
  end

  desc "Clean everything out"
  task clean: :environment do
    CurateGenericWork.all.each(&:destroy!)
    Collection.all.each(&:destroy!)
  end
end

def load_sample_data
  collection = make_langmuir_collection
  first_object = load_first_object
  second_object = load_second_object
  third_object = load_third_object
  [first_object, second_object, third_object].each do |object|
    object.member_of_collections << collection
    object.save
  end
  collection.update_index
end

def make_langmuir_collection
  col = Collection.new
  col.title = ["Robert Langmuir African American photograph collection"]
  col.collection_type_gid = Hyrax::CollectionType.first.gid
  col.visibility = "open"
  col.save
  col
end

def load_first_object
  work = CurateGenericWork.new
  work.depositor = ::User.last.user_key
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
  work.rights_statement_controlled = "Emory University does not control copyright for this image.Â¬â€ This image is made available for individual viewing and reference for educational purposes only such as personal study, preparation for teaching, and research.Â¬â€ Your reproduction, distribution, public display or other re-use of any content beyond a fair use as codified in section 107 of US Copyright Law is at your own risk.Â¬â€ We are always interested in learning more about our collections.Â¬â€ If you have information regarding this photograph, please contact marbl@emory.edu."
  work.rights_statement = ["http://rightsstatements.org/vocab/InC/1.0/"]
  work.subject_names = ["Fake Subject Name 1", "Fake Subject Name 2"]
  work.subject_geo = ["Fake Subject Geo 1", "Fake Subject Geo 2"]
  work.keywords = ["Education: Elementary and Secondary"]
  work.subject_topics = ["Classrooms.", "Tables.", "Blackboards.", "Furnaces.", "Students.", "Chairs.", "Coats."]
  work.uniform_title = "Fake Uniform Title"
  work.table_of_contents = "Fake TOC"
  work.title = ["Students sitting on floor, chairs and tables in classroom with furnace"]
  work.content_type = "http://id.loc.gov/vocabulary/resourceTypes/img"
  work.data_classification = ["Confidential"]
  work.visibility = "open"
  work.copyright_date = "Fake Copyright Date"
  work.rights_holder = ["Fake Rights Holder"]
  work.legacy_rights = "Emory University does not control copyright for this image. This image is made available for individual viewing and reference for educational purposes only such as personal study, preparation for teaching, and research. Your reproduction, distribution, public display or other re-use of any content beyond a fair use as codified in section 107 of US Copyright Law is at your own risk. We are always interested in learning more about our collections. If you have information regarding this photograph, please contact marbl@emory.edu."
  work.date_digitized = "Fake Date Digitized"
  work.transfer_engineer = "Fake Transfer Engineer"
  work.save
  work
end

def load_second_object
  work = CurateGenericWork.new
  work.depositor = ::User.last.user_key
  work.legacy_identifier = ["dams:156626", "MSS1218_B011_I052"]
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
  work.rights_statement_controlled = "Emory University does not control copyright for this image.Â¬â€ This image is made available for individual viewing and reference for educational purposes only such as personal study, preparation for teaching, and research.Â¬â€ Your reproduction, distribution, public display or other re-use of any content beyond a fair use as codified in section 107 of US Copyright Law is at your own risk.Â¬â€ We are always interested in learning more about our collections.Â¬â€ If you have information regarding this photograph, please contact marbl@emory.edu."
  work.rights_statement = ["http://rightsstatements.org/vocab/InC/1.0/"]
  work.subject_names = ["Fake Subject Name 1", "Fake Subject Name 2"]
  work.subject_geo = ["Fake Subject Geo 1", "Fake Subject Geo 2"]
  work.keywords = ["Education: Elementary and Secondary"]
  work.subject_topics = ["Classrooms.", "Tables.", "Blackboards.", "Furnaces.", "Students.", "Chairs.", "Coats."]
  work.uniform_title = "Fake Uniform Title"
  work.table_of_contents = "Fake TOC"
  work.title = ["Students sitting on floor, chairs and tables in classroom with furnace"]
  work.content_type = "http://id.loc.gov/vocabulary/resourceTypes/img"
  work.data_classification = ["Confidential"]
  work.visibility = "open"
  work.copyright_date = "Fake Copyright Date"
  work.rights_holder = ["Fake Rights Holder"]
  work.legacy_rights = "Emory University does not control copyright for this image. This image is made available for individual viewing and reference for educational purposes only such as personal study, preparation for teaching, and research. Your reproduction, distribution, public display or other re-use of any content beyond a fair use as codified in section 107 of US Copyright Law is at your own risk. We are always interested in learning more about our collections. If you have information regarding this photograph, please contact marbl@emory.edu."
  work.date_digitized = "Fake Date Digitized"
  work.transfer_engineer = "Fake Transfer Engineer"
  work.save
  work
end

def load_third_object
  work = CurateGenericWork.new
  work.depositor = ::User.last.user_key
  work.legacy_identifier = ["dams:156758", "MSS1218_B011_I026"]
  work.abstract = "Recto: Faculty and Grauates, University of West Tennessee, 1921, Memphis, Tenn., Hooks Bros. Photo., Nahm Studio, Pueblo, Medicine, E.C. Outten, Panama, P.A. Tirador, P.I., E.P. Henry, Okla., D.W. Briggs, A.B., Ark., J.S. Cobb, M.D., Fla., Nurse Training, E. Cheatham, R.N., C.K. Cribb, R.N., G.M. Moore, Tenn., B.T. Anderson, Miss., L.V. Albudy, Tex., F.L. Avery, Okla., Dentistry, M.R. Ransom, Mo., S.P. Robertson, M.D., S.C., E.L. Hairston, Va., W.H. Young, Tex., B.F. McCleave, M.D., S.C., R.L. Flagg, A.B., M.D., Miss., B.F. McCleave, M.D., T.E. Cox, M.D., F.A. Moore, M.D., B.D. Harrell, M.D., R.L. Flagg, M.D., J.W. Beckette, M.D., N.M. Watson, M.D., O.W. Hooge, M.D., F.W. Thurman, D.D.S., W. Waters, D.D.S., W.E. Cloud, D.D.S., U.S. Walton, D.D.S., O.B. Braithwhite, Dean Dental College, J.C. Hairston, Dean - M.D., C.A. Terrell, M.D., Dean Surgery, B.S. Lynk, Ph.C, Dean - Ph.C., M.V. Lynk, M.S., M.D., LL.G., President"
  work.administrative_unit = "Stuart A. Rose Manuscript, Archives and Rare Book Library"
  work.local_call_number = "MSS 1218"
  work.contact_information = "Fake contact information"
  work.creator = ["Hooks Brothers."]
  work.date_created = "1921"
  work.date_issued = "XXXX"
  work.content_genre = ["card photographs (photographs)"]
  work.holding_repository = "Stuart A. Rose Manuscript, Archives and Rare Book Library"
  work.institution = "Emory University"
  work.primary_language = "Fake Primary Language"
  work.note = ["Fake Note"]
  work.legacy_ark = ["Fake Legacy Ark"]
  work.place_of_production = "Fake Place of Production"
  work.publisher = "Fake Publisher"
  work.rights_statement_controlled = "Emory University does not control copyright for this image.Â¬â€ This image is made available for individual viewing and reference for educational purposes only such as personal study, preparation for teaching, and research.Â¬â€ Your reproduction, distribution, public display or other re-use of any content beyond a fair use as codified in section 107 of US Copyright Law is at your own risk.Â¬â€ We are always interested in learning more about our collections.Â¬â€ If you have information regarding this photograph, please contact marbl@emory.edu."
  work.rights_statement = ["http://rightsstatements.org/vocab/NoC-US/1.0/"]
  work.subject_names = [
    "University of Tennessee, Memphis.",
    "Robertson, S. P., M.D.",
    "Harrell, B. D., M.D."
  ]
  work.subject_geo = ["Memphis (Tenn.)"]
  work.keywords = ["Education: Colleges, universities, and technical colleges"]
  work.subject_topics = [
    "College graduates.",
    "African American photographers.",
    "Nursing.",
    "Medicine.",
    "Dentistry.",
    "Universities and colleges--Faculty."
  ]
  work.uniform_title = "Fake Uniform Title"
  work.table_of_contents = "Fake TOC"
  work.title = ["Faculty and graduates of University of West Tennessee, Memphis, Tenn. in medicine, dentistry and nurse training in 1921"]
  work.content_type = "http://id.loc.gov/vocabulary/resourceTypes/img"
  work.data_classification = ["Confidential"]
  work.visibility = "open"
  work.copyright_date = "Fake Copyright Date"
  work.rights_holder = ["Fake Rights Holder"]
  work.legacy_rights = "Emory University does not control copyright for this image. This image is made available for individual viewing and reference for educational purposes only such as personal study, preparation for teaching, and research. Your reproduction, distribution, public display or other re-use of any content beyond a fair use as codified in section 107 of US Copyright Law is at your own risk. We are always interested in learning more about our collections. If you have information regarding this photograph, please contact marbl@emory.edu."
  work.date_digitized = "Fake Date Digitized"
  work.transfer_engineer = "Fake Transfer Engineer"
  work.save
  work
end
