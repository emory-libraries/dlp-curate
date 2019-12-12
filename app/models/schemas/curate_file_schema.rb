# frozen_string_literal: true

module Schemas
  class CurateFileSchema < ActiveTriples::Schema
    property :file_path, predicate: ::RDF::URI.new('http://metadata.emory.edu/vocab/cor-terms#filePath')
    property :creating_application_name, predicate: ::RDF::Vocab::PREMIS.hasCreatingApplicationName
    property :creating_os, predicate: ::RDF::URI.new('http://metadata.emory.edu/vocab/cor-terms#creatingOS')
    property :puid, predicate: ::RDF::URI.new('http://metadata.emory.edu/vocab/cor-terms#PUID')
  end
end
