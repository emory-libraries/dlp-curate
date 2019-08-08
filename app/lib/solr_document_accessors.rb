# frozen_string_literal: true

# The SolrDocument class needs to have methods defined for each
# attribute you want to access via the WorkPresenter
# this generates these methods based on the attributes that exist on the work
# Right now this will only work with _tesim values
module SolrDocumentAccessors
  CurateGenericWorkAttributes.instance.attributes.each do |method|
    define_method(method.to_sym) do
      self["#{method}_tesim"]
    end
  end
end
