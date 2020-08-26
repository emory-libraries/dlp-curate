# frozen_string_literal: true

module FormHelper
  def all_collections_collection
    Collection.all.map { |c| [c.title.first, c.id] }
  end
end
