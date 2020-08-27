# frozen_string_literal: true

module CollectionShowHelper
  def source_collection_link(value_hsh, request_url)
    if request_url.include? "dashboard"
      tag.a value_hsh[:title], href: "/dashboard/collections/#{value_hsh[:id]}"
    else
      tag.a value_hsh[:title], href: "/collections/#{value_hsh[:id]}"
    end
  end
end
