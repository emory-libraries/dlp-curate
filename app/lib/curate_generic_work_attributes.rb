# frozen_string_literal: true

# A singleton class to get the list of attributes
# from a work.
#
# It is a Singleton so that there is only one of these
# initialized and uses the ||= operator so that when you
# read the attributes property it uses an already initialized
# work.
#
# This is to ensure that we can get a list of the attributes
# programmatically, but without using any unnecessary memory.
class CurateGenericWorkAttributes
  include Singleton
  attr_reader :attributes, :properties, :validators, :local_attributes

  def initialize
    work ||= CurateGenericWork.new
    @local_attributes || work.local_attributes
    @attributes ||= work.local_attributes
    @properties ||= work.send(:properties)
    @validators ||= work.send(:_validators)
  end
end
