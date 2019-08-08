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
  attr_reader :attributes

  def initialize
    @attributes ||= CurateGenericWork.new.local_attributes
  end
end
