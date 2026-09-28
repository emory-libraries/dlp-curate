# frozen_string_literal: true
# [Hyrax-override-v5.2.0] Adds set_noid_id step to Valkyrie transaction pipelines.

if Hyrax.config.valkyrie_transition?
  require Rails.root.join('lib', 'hyrax', 'transactions', 'steps', 'set_noid_id')

  Hyrax::Transactions::Container.register(
    'change_set.set_noid_id',
    Hyrax::Transactions::Steps::SetNoidId.new
  )

  Hyrax::Transactions::WorkCreate::DEFAULT_STEPS = [
    'change_set.set_default_admin_set',
    'change_set.ensure_admin_set',
    'change_set.set_user_as_depositor',
    'change_set.apply',
    'change_set.set_noid_id',
    'work_resource.apply_permission_template',
    'work_resource.save_acl',
    'work_resource.add_file_sets',
    'work_resource.change_depositor',
    'work_resource.add_to_parent'
  ].freeze

  Hyrax::Transactions::CollectionCreate::DEFAULT_STEPS = [
    'change_set.set_user_as_depositor',
    'change_set.set_collection_type_gid',
    'change_set.add_to_collections',
    'change_set.apply',
    'change_set.set_noid_id',
    'collection_resource.apply_collection_type_permissions',
    'collection_resource.save_acl'
  ].freeze

  Rails.application.config.to_prepare do
    Hyrax::Action::CreateValkyrieWork.class_eval do
      def step_args
        {
          'change_set.set_noid_id' => {},
          'work_resource.add_to_parent' => { parent_id: params[:parent_id], user: },
          'work_resource.add_file_sets' => { uploaded_files:, file_set_params: work_attributes[:file_set] },
          'change_set.set_user_as_depositor' => { user: },
          'work_resource.change_depositor' => { user: ::User.find_by_user_key(form.on_behalf_of) },
          'work_resource.save_acl' => { permissions_params: form.input_params["permissions"] }
        }
      end
    end
  end
end
