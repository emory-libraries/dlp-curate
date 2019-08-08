# Generated via
#  `rails generate hyrax:work CurateGenericWork`
module Hyrax
  class CurateGenericWorkPresenter < Hyrax::WorkShowPresenter
    CurateGenericWorkAttributes.instance.attributes.each do |key|
      delegate key.to_sym, to: :solr_document
    end
  end
end
