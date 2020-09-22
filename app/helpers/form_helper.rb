# frozen_string_literal: true

module FormHelper
  # Change below was necessary to institute Source/Deposit Collection structure.
  # For more information, read the SOURCE_DEPOSIT_CHANGES_README.md in dlp-curate's root folder.
  def all_collections_collection
    Collection.all.map { |c| [c.title.first, c.id] }
  end
end
