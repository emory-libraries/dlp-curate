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
    if Hyrax.config.valkyrie_transition?
      work_docs = Hyrax::SolrService.query("has_model_ssim:CurateGenericWork", rows: 1_000_000, fl: "id")
      work_docs.each do |doc|
        resource = Hyrax.query_service.find_by(id: doc["id"])
        Hyrax.persister.delete(resource:)
      end
      col_docs = Hyrax::SolrService.query("has_model_ssim:Collection", rows: 1_000_000, fl: "id")
      col_docs.each do |doc|
        resource = Hyrax.query_service.find_by(id: doc["id"])
        Hyrax.persister.delete(resource:)
      end
    else
      CurateGenericWork.all.each(&:destroy!)
      Collection.all.each(&:destroy!)
    end
  end
end

# rubocop:disable Metrics/MethodLength
def load_sample_data
  collection = make_langmuir_collection
  first_object = load_first_object
  second_object = load_second_object
  third_object = load_third_object
  if Hyrax.config.valkyrie_transition?
    [first_object, second_object, third_object].each do |object|
      object.member_of_collection_ids += [collection.id]
      Hyrax.persister.save(resource: object)
      Hyrax.index_adapter.save(resource: object)
    end
    Hyrax.index_adapter.save(resource: collection)
  else
    [first_object, second_object, third_object].each do |object|
      object.member_of_collections << collection
      object.save
    end
    collection.update_index
  end
end
# rubocop:enable Metrics/MethodLength

def make_langmuir_collection
  if Hyrax.config.valkyrie_transition?
    col = CollectionResource.new
    col.title = ["Robert Langmuir African American photograph collection"]
    col.collection_type_gid = Hyrax::CollectionType.first.gid
    col.visibility = "open"
    Hyrax.persister.save(resource: col)
  else
    col = Collection.new
    col.title = ["Robert Langmuir African American photograph collection"]
    col.collection_type_gid = Hyrax::CollectionType.first.gid
    col.visibility = "open"
    col.save
    col
  end
end

# rubocop:disable Metrics/MethodLength
def build_sample_work(attrs)
  if Hyrax.config.valkyrie_transition?
    work = CurateGenericWorkResource.new
    attrs.each { |key, value| work.public_send("#{key}=", value) if work.respond_to?("#{key}=") }
    Hyrax.persister.save(resource: work)
  else
    work = CurateGenericWork.new
    attrs.each { |key, value| work.public_send("#{key}=", value) }
    work.save
    work
  end
end
# rubocop:enable Metrics/MethodLength

# rubocop:disable Metrics/MethodLength
def sample_work_base_attrs
  {
    depositor:               ::User.last.user_key,
    administrative_unit:     "Stuart A. Rose Manuscript, Archives and Rare Book Library",
    local_call_number:       "MSS 1218",
    contact_information:     "Fake contact information",
    holding_repository:      "Stuart A. Rose Manuscript, Archives and Rare Book Library",
    institution:             "Emory University",
    primary_language:        "Fake Primary Language",
    notes:                   ["Fake Note"],
    emory_ark:               ["Fake Legacy Ark"],
    place_of_production:     "Fake Place of Production",
    publisher:               "Fake Publisher",
    emory_rights_statements: ["Emory University does not control copyright for this image."],
    uniform_title:           "Fake Uniform Title",
    table_of_contents:       "Fake TOC",
    content_type:            "http://id.loc.gov/vocabulary/resourceTypes/img",
    data_classifications:    ["Confidential"],
    visibility:              "open",
    copyright_date:          "Fake Copyright Date",
    rights_holders:          ["Fake Rights Holder"],
    legacy_rights:           "Emory University does not control copyright for this image.",
    date_digitized:          "Fake Date Digitized",
    transfer_engineer:       "Fake Transfer Engineer"
  }
end
# rubocop:enable Metrics/MethodLength

def load_first_object
  build_sample_work(sample_work_base_attrs.merge(
    other_identifiers: ["dams:179629", "MSS1218_B011_I052"],
    abstract:          "Fake Abstract",
    creator:           ["Fake Creator"],
    date_created:      "XXXX",
    date_issued:       "XXXX",
    content_genres:    ["card photographs (photographs)"],
    rights_statement:  ["http://rightsstatements.org/vocab/InC/1.0/"],
    subject_names:     ["Fake Subject Name 1", "Fake Subject Name 2"],
    subject_geo:       ["Fake Subject Geo 1", "Fake Subject Geo 2"],
    keywords:          ["Education: Elementary and Secondary"],
    subject_topics:    ["Classrooms.", "Tables.", "Blackboards.", "Furnaces.", "Students.", "Chairs.", "Coats."],
    title:             ["Students sitting on floor, chairs and tables in classroom with furnace"]
  ))
end

def load_second_object
  build_sample_work(sample_work_base_attrs.merge(
    other_identifiers: ["dams:156626", "MSS1218_B011_I052"],
    abstract:          "Fake Abstract",
    creator:           ["Fake Creator"],
    date_created:      "XXXX",
    date_issued:       "XXXX",
    content_genres:    ["card photographs (photographs)"],
    rights_statement:  ["http://rightsstatements.org/vocab/NoC-US/1.0/"],
    subject_names:     ["Fake Subject Name 1", "Fake Subject Name 2"],
    subject_geo:       ["Fake Subject Geo 1", "Fake Subject Geo 2"],
    keywords:          ["Education: Elementary and Secondary"],
    subject_topics:    ["Classrooms.", "Tables.", "Blackboards.", "Furnaces.", "Students.", "Chairs.", "Coats."],
    title:             ["Students sitting on floor, chairs and tables in classroom with furnace"]
  ))
end

# rubocop:disable Metrics/MethodLength
def load_third_object
  build_sample_work(sample_work_base_attrs.merge(
    other_identifiers: ["dams:156758", "MSS1218_B011_I026"],
    abstract:          "Recto: Faculty and Grauates, University of West Tennessee, 1921, Memphis, Tenn.",
    creator:           ["Hooks Brothers."],
    date_created:      "1921",
    date_issued:       "XXXX",
    content_genres:    ["card photographs (photographs)"],
    rights_statement:  ["http://rightsstatements.org/vocab/NoC-US/1.0/"],
    subject_names:     ["University of Tennessee, Memphis.", "Robertson, S. P., M.D.", "Harrell, B. D., M.D."],
    subject_geo:       ["Memphis (Tenn.)"],
    keywords:          ["Education: Colleges, universities, and technical colleges"],
    subject_topics:    ["Classrooms.", "African American photographers.", "Nursing.", "Medicine.", "Dentistry.",
                        "Universities and colleges--Faculty."],
    title:             ["Faculty and graduates of University of West Tennessee, Memphis, Tenn. in medicine, dentistry and nurse training in 1921"]
  ))
end
# rubocop:enable Metrics/MethodLength
