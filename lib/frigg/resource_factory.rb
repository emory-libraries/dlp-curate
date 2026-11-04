# frozen_string_literal: true
# [Hyrax-override-hyrax-close_the_frigg_door]

module Frigg
  # Provides access to generic methods for converting to/from
  # {Valkyrie::Resource} and {Valkyrie::Persistence::Postgres::ORM::Resource}.
  class ResourceFactory < Valkyrie::Persistence::Fedora::Persister::ResourceFactory
  end
end
