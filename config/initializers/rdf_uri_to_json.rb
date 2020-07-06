# frozen_string_literal: true
# [Valkyrie-overwrite-v1.7.1] This is fixed in Valkyrie-v2.1.0. Remove this
# when we upgrade to v2.1.0 or higher.
##
# These patches are necessary for the postgres adapter to build JSON-LD versions
# of RDF objects when `to_json` is called on them - that way they're stored in
# the database as a standard format.
# Refer: https://github.com/samvera/valkyrie/pull/810
module RDF
  class Literal
    def as_json(*_args)
      ::JSON::LD::API.fromRdf([RDF::Statement.new(RDF::URI(""), RDF::URI(""), self)])[0][""][0]
    end
  end
  class URI
    def as_json(*_args)
      ::JSON::LD::API.fromRdf([RDF::Statement.new(RDF::URI(""), RDF::URI(""), self)])[0][""][0]
    end
  end
end
