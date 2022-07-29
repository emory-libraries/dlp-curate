# frozen_string_literal: true

FactoryBot.define do
  factory :work, aliases: [:generic_work, :private_generic_work], class: CurateGenericWork do
    transient do
      user { create(:user) }
      # Set to true (or a hash) if you want to create an admin set
      with_admin_set { false }
    end

    # It is reasonable to assume that a work has an admin set; However, we don't want to
    # go through the entire rigors of creating that admin set.
    before(:create) do |work, evaluator|
      if evaluator.with_admin_set
        attributes = {}
        attributes[:id] = work.admin_set_id if work.admin_set_id.present?
        attributes = evaluator.with_admin_set.merge(attributes) if evaluator.with_admin_set.respond_to?(:merge)
        admin_set = create(:admin_set, attributes)
        work.admin_set_id = admin_set.id
      end
    end

    after(:create) do |work, _evaluator|
      work.save! if work.member_of_collections.present?
    end

    visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
    title { ["Test title"] }

    after(:build) do |work, evaluator|
      p_w = work.preservation_workflow.build
      p_w.workflow_type = 'example'
      p_w.workflow_notes = 'notes'
      p_w.workflow_rights_basis = 'rights basis'
      p_w.workflow_rights_basis_note = 'note'
      p_w.workflow_rights_basis_date = '02/02/2012'
      p_w.workflow_rights_basis_reviewer = 'reviewer'
      p_w.workflow_rights_basis_uri = 'uri'
      p_w.persist!
      work.apply_depositor_metadata(evaluator.user.user_key)
    end

    factory :work_with_full_metadata do
      abstract { 'Abstract' }
      access_restriction_notes { ['true'] }
      administrative_unit { 'Emory University Archives' }
      author_notes { 'None found' }
      conference_dates { '1995' }
      conference_name { 'None' }
      contact_information { 'Call here' }
      content_genres { ['Photos'] }
      content_type { 'http://id.loc.gov/vocabulary/resourceTypes/aud' }
      contributors { ['Someone else'] }
      copyright_date { '1922' }
      creator { ['the author'] }
      data_classifications { ['open'] }
      data_collection_dates { ['785'] }
      data_producers { ['Megacorp'] }
      data_source_notes { ['Found materials'] }
      date_created { '1992' }
      date_digitized { '2102' }
      date_issued { '1999' }
      date_modified { '2023' }
      date_uploaded { '2001' }
      deduplication_key { 'dedupestring' }
      edition { 'first' }
      emory_ark { ['255555'] }
      emory_rights_statements { ['This is my rights statement text'] }
      extent { 'A very large extent' }
      final_published_versions { ['http://example.com'] }
      geographic_unit { 'cm' }
      grant_agencies { ['For five years'] }
      grant_information { ['More grant information'] }
      holding_repository { 'Emory Libraries' }
      institution { 'Emory' }
      internal_rights_note { 'check again please' }
      isbn { '54321' }
      issn { '123435' }
      issue { '123' }
      keywords { ['photos'] }
      legacy_rights { 'no' }
      local_call_number { '1234' }
      notes { ['Many found'] }
      other_identifiers { ['184975'] }
      page_range_end { '1' }
      page_range_start { '0' }
      parent_title { 'A parent title' }
      place_of_production { 'Antartic' }
      primary_language { 'Esperanto' }
      primary_repository_ID { 'http://example.com' }
      publisher { 'emory' }
      publisher_version { '1' }
      re_use_license { 'https://creativecommons.org/licenses/by/4.0/' }
      related_datasets { ['http://example.com'] }
      related_material_notes { ['More stuff'] }
      related_publications { ['https://example.com'] }
      rights_documentation { 'https://example.com' }
      rights_holders { ['Emory'] }
      rights_statement { ['http://rightsstatements.org/vocab/InC/1.0/'] }
      scheduled_rights_review { 'true' }
      scheduled_rights_review_note { 'check please' }
      sensitive_material { 'false' }
      sensitive_material_note { 'do not check' }
      series_title { 'A series' }
      sponsor { 'Another person' }
      staff_notes { ['Did not check'] }
      subject_geo { ['Artic'] }
      subject_names { ['Someone'] }
      subject_time_periods { ['Neolithic'] }
      subject_topics { ['Photographs'] }
      sublocation { 'Emory 2' }
      system_of_record_ID { '1976578' }
      table_of_contents { '1. A Toc' }
      technical_note { '1mb' }
      transfer_engineer { 'yes' }
      uniform_title { 'More uniform title' }
      volume { '1234' }
      preservation_workflow_terms do
        ['{"workflow_type":"example","workflow_notes":"notes","workflow_rights_basis":"basis","workflow_rights_basis_note":"note",
                                   "workflow_rights_basis_date":"02/02/2012","workflow_rights_basis_reviewer":"reviewer","workflow_rights_basis_uri":"uri"}']
      end
    end

    factory :public_generic_work, aliases: [:public_work], traits: [:public]

    trait :public do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    end

    factory :private_work do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
    end

    factory :public_low_work do
      visibility { ::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES }
    end

    factory :emory_low_work do
      visibility { ::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW }
    end

    # Emory High Download is a re-use of the "authenticated"/"registered" visibility
    factory :emory_high_work do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
    end

    factory :rose_high_work do
      visibility { ::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH }
    end

    factory :registered_generic_work do
      read_groups { ["registered"] }
    end

    factory :work_with_one_file do
      before(:create) do |work, evaluator|
        work.ordered_members << create(:file_set, user: evaluator.user, title: ['A Contained FileSet'], label: 'filename.pdf')
      end
    end

    factory :work_with_files do
      before(:create) { |work, evaluator| 2.times { work.ordered_members << create(:file_set, user: evaluator.user) } }
    end

    factory :work_with_ordered_files do
      before(:create) do |work, evaluator|
        work.ordered_members << create(:file_set, user: evaluator.user)
        work.ordered_member_proxies.insert_target_at(0, create(:file_set, user: evaluator.user))
      end
    end

    factory :work_with_one_child do
      before(:create) do |work, evaluator|
        work.ordered_members << create(:work, user: evaluator.user, title: ['A Contained Work'])
      end
    end

    factory :work_with_two_children do
      before(:create) do |work, evaluator|
        work.ordered_members << create(:work, user: evaluator.user, title: ['A Contained Work'], id: "BlahBlah1")
        work.ordered_members << create(:work, user: evaluator.user, title: ['Another Contained Work'], id: "BlahBlah2")
      end
    end

    factory :work_with_representative_file do
      before(:create) do |work, evaluator|
        work.ordered_members << create(:file_set, user: evaluator.user, title: ['A Contained FileSet'])
        work.representative_id = work.members[0].id
      end
    end

    factory :work_with_file_and_work do
      before(:create) do |work, evaluator|
        work.ordered_members << create(:file_set, user: evaluator.user)
        work.ordered_members << create(:work, user: evaluator.user)
      end
    end

    factory :with_embargo_date do
      # build with defaults:
      # let(:work) { create(:embargoed_work) }

      # build with specific values:
      # let(:embargo_attributes) do
      #   { embargo_date: Date.tomorrow.to_s,
      #     current_state: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
      #     future_state: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      # end
      # let(:work) { create(:embargoed_work, with_embargo_attributes: embargo_attributes) }

      transient do
        with_embargo_attributes { false }
        embargo_date { Date.tomorrow.to_s }
        current_state { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
        future_state { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      end
      factory :embargoed_work do
        after(:build) do |work, evaluator|
          if evaluator.with_embargo_attributes
            work.apply_embargo(evaluator.with_embargo_attributes[:embargo_date],
                               evaluator.with_embargo_attributes[:current_state],
                               evaluator.with_embargo_attributes[:future_state])
          else
            work.apply_embargo(evaluator.embargo_date,
                               evaluator.current_state,
                               evaluator.future_state)
          end
        end
      end
      factory :embargoed_work_with_files do
        after(:build) do |work, evaluator|
          if evaluator.with_embargo_attributes
            work.apply_embargo(evaluator.with_embargo_attributes[:embargo_date],
                               evaluator.with_embargo_attributes[:current_state],
                               evaluator.with_embargo_attributes[:future_state])
          else
            work.apply_embargo(evaluator.embargo_date,
                               evaluator.current_state,
                               evaluator.future_state)
          end
        end
        after(:create) { |work, evaluator| 2.times { work.ordered_members << create(:file_set, user: evaluator.user) } }
      end
    end

    factory :with_lease_date do
      # build with defaults:
      # let(:work) { create(:leased_work) }

      # build with specific values:
      # let(:lease_attributes) do
      #   { lease_date: Date.tomorrow.to_s,
      #     current_state: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
      #     future_state: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
      # end
      # let(:work) { create(:leased_work, with_lease_attributes: lease_attributes) }

      transient do
        with_lease_attributes { false }
        lease_date { Date.tomorrow.to_s }
        current_state { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
        future_state { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
      end
      factory :leased_work do
        after(:build) do |work, evaluator|
          if evaluator.with_lease_attributes
            work.apply_lease(evaluator.with_lease_attributes[:lease_date],
                             evaluator.with_lease_attributes[:current_state],
                             evaluator.with_lease_attributes[:future_state])
          else
            work.apply_lease(evaluator.lease_date,
                             evaluator.current_state,
                             evaluator.future_state)
          end
        end
      end
      factory :leased_work_with_files do
        after(:build) do |work, evaluator|
          if evaluator.with_lease_attributes
            work.apply_lease(evaluator.with_lease_attributes[:lease_date],
                             evaluator.with_lease_attributes[:current_state],
                             evaluator.with_lease_attributes[:future_state])
          else
            work.apply_lease(evaluator.lease_date,
                             evaluator.current_state,
                             evaluator.future_state)
          end
        end
        after(:create) { |work, evaluator| 2.times { work.ordered_members << create(:file_set, user: evaluator.user) } }
      end
    end
  end

  # Doesn't set up any edit_users
  factory :work_without_access, class: CurateGenericWork do
    title { ['Test title'] }
    depositor { create(:user).user_key }
  end
end
