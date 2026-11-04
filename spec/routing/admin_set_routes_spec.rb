# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Admin set routes', type: :routing do
  routes { Hyrax::Engine.routes }

  it 'routes the Hyrax 5 default admin set id' do
    expect(get: '/admin/admin_sets/admin_set_default').to route_to(
      controller: 'hyrax/admin/admin_sets',
      action:     'show',
      id:         'admin_set_default'
    )
  end

  it 'routes the legacy default admin set id that contains a slash' do
    expect(get: '/admin/admin_sets/admin_set/default').to route_to(
      controller: 'hyrax/admin/admin_sets',
      action:     'show',
      id:         'admin_set/default'
    )
  end

  it 'routes edit for the legacy default admin set id' do
    expect(get: '/admin/admin_sets/admin_set/default/edit').to route_to(
      controller: 'hyrax/admin/admin_sets',
      action:     'edit',
      id:         'admin_set/default'
    )
  end
end
