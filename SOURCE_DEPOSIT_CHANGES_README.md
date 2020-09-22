# Summary Of Source/Deposit Collection Adjustments
## Table of Contents
1. [Overview](#overview)
2. [Models](#models)
3. [Views](#views)
4. [Controllers](#controllers)
5. [Assets](#assets)
6. [Forms](#forms)
7. [Helpers](#helpers)
8. [Importers](#importers)
9. [Indexers](#indexers)
10. [Jobs](#jobs)
11. [Presenters](#presenters)
12. [Search Builders](#search-builders)
13. [Initializers](#initializers)
14. [Config](#config)
15. [DB/Migrate](#dbmigrate)
## Overview
Just after the launch of Curate v1, it was determined that the greater the number of Works that are associated with a single Collection, the longer that any further ingestions of Works to that Collection would take. The best solution to this issue was to create, in essence, sub-containers for each primary Collection. The original Collection would take on the moniker of "Source", while the secondary collections would be deemed "Deposit".  Works would hold associations to both their direct and overarching parents (sometimes the same Collection). Several customizations upon our Hyrax backbone were needed to implement the parent/child relationships. Below, you will find descriptions of these changes grouped by class and module types.
## Models
### [Collection](https://github.com/emory-libraries/dlp-curate/blob/main/app/models/collection.rb)
- `:deposit_collection_ids`: this multi-value attribute was added to retain all of the child collection IDs that are associated to a Collection instance. The presence of IDs in an instance means that it is a Source Collection.
- `:source_collection_id`: a single-valued field that holds the parent collection ID. An ID populated in this field means that object is a Deposit Collection.
### [CurateGenericWork](https://github.com/emory-libraries/dlp-curate/blob/main/app/models/curate_generic_work.rb)
- `:source_collection_id`: this required field ties the Work to the Source Collection with an ID string.
### [SolrDocument](https://github.com/emory-libraries/dlp-curate/blob/main/app/models/solr_document.rb)
- `#source_collection_title`: a method allowing the SolrDocument rails object to access the value of `source_collection_title_ssim` as if it were stored in ActiveRecord. 
## Views
### [hyrax/admin/collection\_types/\_form_settings.html.erb](https://github.com/emory-libraries/dlp-curate/blob/main/app/views/hyrax/admin/collection_types/_form_settings.html.erb)
- A checkbox is inserted at line 41 to give a new CollectionType the option of being deposit-only.
### [hyrax/base/\_relationships\_parent_rows.html.erb](https://github.com/emory-libraries/dlp-curate/blob/main/app/views/hyrax/base/_relationships_parent_rows.html.erb)
- On lines 17 through 25, a Source Collection header and link is added to this Work show page partial.
### [hyrax/collections/\_deposit_collections.html.erb](https://github.com/emory-libraries/dlp-curate/blob/main/app/views/hyrax/collections/_deposit_collections.html.erb)
- This is a new partial that inserts a header and Deposit Collection link(s) for a Source Collection's show pages.
### [hyrax/collections/\_source_collection.html.erb](https://github.com/emory-libraries/dlp-curate/blob/main/app/views/hyrax/collections/_source_collection.html.erb)
- This is a new partial that inserts a header and Source Collection link for a Deposit Collection's show pages.
### [hyrax/collections/show.html.erb](https://github.com/emory-libraries/dlp-curate/blob/main/app/views/hyrax/collections/show.html.erb)
- Between lines 98 and 102, inserts partial calls to both the Deposit and Source Collection links `html`.
### [hyrax/dashboard/collections/show.html.erb](https://github.com/emory-libraries/dlp-curate/blob/main/app/views/hyrax/dashboard/collections/show.html.erb)
- This Hyrax page overwrite only reflects changes between lines 64 and 76. Here, we are inserting two partial calls to the Deposit and Source Collection links `html`.
### [records/edit\_fields/\_deposit\_collection\_ids.html.erb](https://github.com/emory-libraries/dlp-curate/blob/main/app/views/records/edit_fields/_deposit_collection_ids.html.erb)
- A partial that effectively overrides Hyrax/Simple Form's default input tag so that only admins can adjust the `deposit_collection_id` field. Also institutes a multi-valued pull-down filled with all Collection objects.
### [records/edit_fields/\_source\_collection\_id.html.erb](https://github.com/emory-libraries/dlp-curate/blob/main/app/views/records/edit_fields/_source_collection_id.html.erb)
- Another override of Hyrax/Simple Form's default input tag that restricts the `source_collection_id` field to admins only. This institutes a single-valued pull-down filled with all Collection objects.
## Controllers
### [CatalogController](https://github.com/emory-libraries/dlp-curate/blob/main/app/controllers/catalog_controller.rb)
- The Collection facet field now uses `source_collection_title_ssim` as it's filter value. 
### [Hyrax::Admin::CollectionTypesControllerOverride](https://github.com/emory-libraries/dlp-curate/blob/main/app/controllers/hyrax/admin/collection_types_controller_override.rb)
- This only overrides the `#collection_type_params` method from `Hyrax::Admin::CollectionTypesController`, adding `:deposit_only_collection` into the permitted params.
## Assets
### [stylesheets/curate.scss](https://github.com/emory-libraries/dlp-curate/blob/main/app/assets/stylesheets/curate.scss)
- The `scss` between lines 103 and 106 adjusts the padding and margin for the Source Collection link on Collection show pages.
## Forms
### [hyrax/forms/admin/collection_type_form.rb](https://github.com/emory-libraries/dlp-curate/blob/main/app/forms/hyrax/forms/admin/collection_type_form.rb)
- `Hyrax::Forms::Admin::CollectionTypeForm` had to be overridden so that `:deposit_only_collection` could be delegated to `:collection_type`.
### [hyrax/forms/collection_form.rb](https://github.com/emory-libraries/dlp-curate/blob/main/app/forms/hyrax/forms/collection_form.rb)
- `:source_collection_id` and `:deposit_collection_ids` had to be added to the `terms` and `secondary_terms` arrays, since it feeds the logic that automatically generates Collection's new/edit input fields. 
### [hyrax/curate_generic_work_form.rb](https://github.com/emory-libraries/dlp-curate/blob/main/app/forms/hyrax/curate_generic_work_form.rb)
- `:source_collection_id` had to be added to the `terms` and `primary_admin_metadata_fields` arrays, since it feeds the logic that automatically generates Works' new/edit input fields. 
## Helpers
### [CollectionShowHelper](https://github.com/emory-libraries/dlp-curate/blob/main/app/helpers/collection_show_helper.rb)
- `#collection_link` dynamically creates the right link based upon whether the user's on the Dashboard or the public Collection show page.
### [FormHelper](https://github.com/emory-libraries/dlp-curate/blob/main/app/helpers/form_helper.rb)
- `#all_collections_collection` creates an array of arrays each containing Collection object's titles and ids. This supplies the select fields' collection attributes in the Collection new/edit forms. 
## Importers
### [CurateMapper](https://github.com/emory-libraries/dlp-curate/blob/main/app/importers/curate_mapper.rb)
- `source_collection_id` is added to `CURATE_TERMS_MAP` so that it is expected and accepted during CSV imports.
### [LangmuirPreprocessor](https://github.com/emory-libraries/dlp-curate/blob/main/app/importers/langmuir_preprocessor.rb)
- Curate's Product Owner specified that `source_collection_id` should be on the processed CSV output, even if it is not present on the input file. The `exclusion_guard` method was applied to the `@merged_headers` instance variable so that it is inserted if not found in the `@source_csv.headers`.
### [YellowbackPreprocessor](https://github.com/emory-libraries/dlp-curate/blob/main/app/importers/yellowback_preprocessor.rb)
- `source_collection_id` is inserted into `HEADER_FIELDS`, so that the field is included in the output file, and `pull_list_mappings`, in order for the values to be pulled from the input CSV.
## Indexers
### [CurateCollectionIndexer](https://github.com/emory-libraries/dlp-curate/blob/main/app/indexers/curate_collection_indexer.rb)
- `source_collection_title_for_collections_ssim` and `deposit_collection_titles_tesim`: both of these fields are stubbed with the `:title` attribute associated to the object's respective Source and Deposit Collection values.
- `deposit_collection_ids_tesim`: declared here to ensure `solr_document` objects carry the Deposit Collection IDs over.
## Jobs
### [CollectionFilesIngestedJob](https://github.com/emory-libraries/dlp-curate/blob/main/app/jobs/collection_files_ingested_job.rb)
- `#collection_works`: with the search originally focused on `:member_of_collection_ids_ssim` to match with the current `collection_id`, this had to swap out to `:source_collection_id_tesim`.
- `#source_collections`: this logic had to be added so that the focus shifted to Collections with CollectionTypes not set to Deposit-Only. 
## Presenters
### [Hyrax::CollectionPresenter](https://github.com/emory-libraries/dlp-curate/blob/main/app/presenters/hyrax/collection_presenter.rb)
The following methods were added to the Presenter so that Deposit and Source Collection details could pass over to the Collection views 
- `#deposit_collection?`: this is a boolean method that returns true if the object is a Deposit Collection.
- `#source_collection_object`: returns a hash of Source Collection `:title` and `:id`.
- `#deposit_collection_ids`: pulls the needed Deposit Collection IDs from the `solr_document`.
- `#deposit_collections`: creates an array of hashes, each containing the `:title` and `:id` of every Deposit Collection associated to the object.
### [Hyrax::CurateGenericWorkPresenter](https://github.com/emory-libraries/dlp-curate/blob/main/app/presenters/hyrax/curate_generic_work_presenter.rb)
- `:source_collection_title` is delegated to the `:solr_document` so that `presenter.source_collection_title` calls won't look for a method created within the class. 
## Search Builders
### [Hyrax::CollectionMemberSearchBuilder](https://github.com/emory-libraries/dlp-curate/blob/main/app/search_builders/hyrax/collection_member_search_builder.rb)
- This class was pulled in as an overwrite of Hyrax' class so that `#member_of_collection` could include Collections' associated Deposit Collection Works alongside the Source Collection Works.
## Initializers
### [Hyrax::My::WorksController](https://github.com/emory-libraries/dlp-curate/blob/main/config/initializers/works_controller.rb)
- `self.configure_facets`: this method is created and called so it can tap into the original `configure_blacklight` grid and add in a facet labeled "Source Collection" onto the Works index.
## Config
### [application.rb](https://github.com/emory-libraries/dlp-curate/blob/main/config/application.rb)
- In order to overwrite `Hyrax::Admin::CollectionTypesController` effectively, we have to `prepend` `CollectionTypesControllerOverride` onto it here.
## DB/Migrate
### [AddDepositOnlyCollectionToHyraxCollectionTypes](https://github.com/emory-libraries/dlp-curate/blob/main/db/migrate/20200818185318_add_deposit_only_collection_to_hyrax_collection_types.rb)
- Added `:deposit_only_collection` onto the `:hyrax_collection_types` table so future Collections can have a Deposit-Only CollectionType.
