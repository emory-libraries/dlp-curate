# frozen_string_literal: true

module FormHelper
  # Change below was necessary to institute Source/Deposit Collection structure.
  # For more information, read the SOURCE_DEPOSIT_CHANGES_README.md in dlp-curate's root folder.
  def all_collections_collection
    results = Hyrax::SolrService.query("has_model_ssim:Collection", rows: 1_000_000, fl: "id,title_tesim")
    results.map { |doc| [Array(doc["title_tesim"]).first, doc["id"]] }
  end
end
