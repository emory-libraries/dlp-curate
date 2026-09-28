# frozen_string_literal: true
# [Hyrax-override-hyrax-v5.2.0]
# Hyrax 5 dropped the `id: /.+/` constraint on admin_sets routes when DEFAULT_ID
# changed from "admin_set/default" to "admin_set_default". Existing repositories
# still have the legacy ID; without this constraint `/admin/admin_sets/admin_set/default`
# is a routing 404.
Hyrax::Engine.routes.prepend do
  namespace :admin do
    resources :admin_sets, constraints: { id: /.+/ } do
      member do
        get :files
      end
      resource :permission_template
    end
  end
end
