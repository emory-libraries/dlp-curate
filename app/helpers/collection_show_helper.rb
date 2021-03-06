# frozen_string_literal: true

module CollectionShowHelper
  # Change below was necessary to institute Source/Deposit Collection structure.
  # For more information, read the SOURCE_DEPOSIT_CHANGES_README.md in dlp-curate's root folder.
  def collection_link(value_hsh, request_url)
    if request_url.include? "dashboard"
      tag.a value_hsh[:title], href: "/dashboard/collections/#{value_hsh[:id]}"
    else
      tag.a value_hsh[:title], href: "/collections/#{value_hsh[:id]}"
    end
  end
end
