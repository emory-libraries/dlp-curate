# Ingestion Processes Tutorial
## Table Of Contents
1. [Reference Materials](#reference-materials)
2. [To Better Understand Hyrax](#to-better-understand-hyrax)
3. [Actors](#actors)
    - [CurateGenericWorkActor](#curategenericworkactor)
    - [FileSetActor](#filesetactor)
4. [Jobs](#jobs)
    - [AttachFilesToWorkJob](#attachfilestoworkjob)
    - [CharacterizeJob](#characterizejob)
    - [CreateDerivativesJob](#createderivativesjob)
5. [Bulk Import Processing Sequence](#bulk-import-processing-sequence)
6. [Preservation Events Quick Reference](#preservation-events-quick-reference)
## Reference Materials
The following sites were key in shedding light on internal Samvera processes that are the backbone of DLP's customizations. 
- [Samvera's homepage](https://samvera.github.io/index.html)
- [Samvera's ActiveFedora Tutorial](https://github.com/samvera/active_fedora/wiki)
- [Samvera's Actor Stack](https://samvera.github.io/actor_stack.html)
## To Better Understand Hyrax
The creation of curation objects inside of Hyrax depends upon a custom-built [Rack Middleware Stack](https://guides.rubyonrails.org/rails_on_rack.html). In essence, it is a coding design pattern that establishes an environment object, which is passed from Actor to Actor. The [custom stack's Actors](https://github.com/samvera/hyrax/blob/v3.4.2/app/services/hyrax/default_middleware_stack.rb) each have a responsibility to either verify, groom, persist, associate, guard, or clean up, all while logging the success/failure of each operation. Some processes actually start and end in the middle of this stack, while others have to rearrange or inject custom Actors to operate properly.  

For an example of how the stack works, visit this [link](https://samvera.github.io/what-happens-deposit-2.0.html) to see how Hyrax ingests a Work out-of-the-box. The Digital Library Program' Curate application has overridden and customized many of Hyrax' [Actors](https://github.com/emory-libraries/dlp-curate/tree/main/app/actors/hyrax/actors) and associated [Jobs](https://github.com/emory-libraries/dlp-curate/tree/main/app/jobs) to accomplish additional documentation of Preservation Events and other needed features. Below are some of the customizations.
## Actors
### [CurateGenericWorkActor](https://github.com/emory-libraries/dlp-curate/blob/main/app/actors/hyrax/actors/curate_generic_work_actor.rb)
This is the model actor for every curation piece we ingest. If you visit the link above, notice the comment line stating that this Actor was automatically created by a Rails generator action. That's because Hyrax allows flexibility with the naming convention of the Generic Work Model.
This Actor inherits its methods from Hyrax' [BaseActor](https://github.com/samvera/hyrax/blob/v3.4.2/app/actors/hyrax/actors/base_actor.rb), although two of the methods needed revisions to add needed functionality:
- `#create`: because DLP's Digital Collections is a digital archive intended to house all works indefinitely, preservation documentation is extremely important. Every event of creation or modification needs to persist alongside the work and its materials. The creation of any work coincides with the initiation of two `PreservationEvent` objects:
    1. `Validation`: confirms that the submission package was validated.
    2.  `Policy Assignment`: establishes the visibility and access of the Work.
- `#apply_save_data_to_curation_concern`: this method, called within the `#create` command, applies the attributes assigned to the environment object (`env`) to the associated `curation_concern` after properly formatting those attributes. 
    - When processing imports from a CSV, certain lines will have no metadata because they are intended for the file(s) attached to the  `CurateGenericWork`.  Those lines will have an "skip_metadata" attribute passed along, triggering a skipping of applying data to that `curation_concern`.
    - In the process of adding [`PreservationEvent`](https://github.com/emory-libraries/dlp-curate/blob/main/app/models/preservation_event.rb)s and [`PreservationWorkflow`](https://github.com/emory-libraries/dlp-curate/blob/main/app/models/preservation_workflow.rb)s to the `curation_concern`, software engineering found that, since these two models are nested attributes, purely passing along an array of objects to the ActiveFedora system wouldn't work. [This block](https://github.com/emory-libraries/dlp-curate/blob/f8c5706844f6e6b04193cc2dbe5c6c6bde4778c4/app/actors/hyrax/actors/curate_generic_work_actor.rb#L24) was needed to push those nested objects into a Fedora object. For a better understanding of how Rails interacts with Fedora objects, visit this [link](https://github.com/samvera/active_fedora/wiki/Lesson:-Using-Rails-Nested-Attributes-behavior-to-modify-Nested-Nodes).

### [FileSetActor](https://github.com/emory-libraries/dlp-curate/blob/main/app/actors/hyrax/actors/file_set_actor.rb)
This is an overwrite of Hyrax' [FileSetActor](https://github.com/samvera/hyrax/blob/v3.4.2/app/actors/hyrax/actors/file_set_actor.rb). This actor attaches `FileSet`s to a `CurateGenericWork`. Changes that were needed are: 
- `#create_content`, `#update_content`, and `#wrapper!`: a customized `FileSet` model was utilized, needing a different default `relation` argument set, as well as accepting a newly created argument ([`preferred`](https://github.com/emory-libraries/dlp-curate/blob/main/app/models/file_set.rb#L76)) that denotes which file should be used as the primary.
- `#create_metadata`: a new argument (`fileset_use`) was needed to distinguish how the file was to be used. This argument is passed into the `FileSet`'s Fedora object as the `pcdm_use` attribute.
- `#attach_to_work`: passing this `file_set` into `work.ordered_members` is omitted because the `ordered_members` association is not utilized in this Actor, but rather in its Job relative.
- `#fileset_name`: this method was added as a convenience when this Actor is used in other Jobs and RSpec. It makes assigning `FileSet`s `label`s and `title`s easier.
## Jobs
### [AttachFilesToWorkJob](https://github.com/emory-libraries/dlp-curate/blob/main/app/jobs/attach_files_to_work_job.rb)
This is an overwrite of Hyrax' [AttachFilesToWorkJob](https://github.com/samvera/hyrax/blob/v3.4.2/app/jobs/attach_files_to_work_job.rb). The Job invokes the `FileSetActor` class so that the Actor is available out of the constraints of the Middleware Stack. The following changes were necessary for this Actor:
- `#process_fileset`: `AttachFilesToWorkJob` had to accept multiple files into one `FileSet`, which Hyrax is not ready for out-of-the-box. This method was created so that multiple types of files could get attached, as well as the `preferred` attribute assigned.
- `#perform`: the metadata and content creation calls that were originally in this method have been moved to `process_fileset`.
- `#preferred_file`: provides logic for which file is deemed the preferred item.
### [CharacterizeJob](https://github.com/emory-libraries/dlp-curate/blob/main/app/jobs/characterize_job.rb)
This is an overwrite of Hyrax' [CharacterizeJob](https://github.com/samvera/hyrax/blob/v3.4.2/app/jobs/characterize_job.rb). This Job analyzes and provides details about a file attached to a `FileSet`. The needed changes are:
- `#perform`: The `#characterize` private method has been eliminated and rolled into this method.  The `CreateDerivativesJob.perform_later` call has been removed since `FileSetActor` takes care of that processing. Also, `PreservationEvents` has been included and the following event has been recorded onto the work:
    1. `Characterization`: technical metadata extracted from file, format identified, and file validated.
### [CreateDerivativesJob](https://github.com/emory-libraries/dlp-curate/blob/main/app/jobs/create_derivatives_job.rb)
This is an overwrite of Hyrax' [CreateDerivativesJob](https://github.com/samvera/hyrax/blob/v3.4.2/app/jobs/create_derivatives_job.rb). This Job creates a Thumbnail from the image passed to it. The following are the changes made to the Hyrax version:
- `#perform`: The generation of thumbnails using MiniMagick has proven problematic and the addition of error logging has been implemented because of it.
[//]: (Deprecation Warning: As of Curate v3, Zizia will be removed. Bulkrax will become the lone importing tool, which means that the following section can either be eliminated completely or rewritten to describe Bulkrax' processing sequence.)
## Bulk Import Processing Sequence
The following is each procedure in order of start to finish that a CSV uploaded to Curate Dashboard's "Import Content From a CSV" goes through.
1. [`Zizia::StartCsvImportJob`](https://github.com/curationexperts/zizia/blob/v6.0.1/app/jobs/zizia/start_csv_import_job.rb)
    The CSV uploaded into the importer gets processed by the Zizia gem. This job is initiated and passes the CSV object to the next method.
2. [`ModularImporter#import`](https://github.com/curationexperts/zizia/blob/v6.0.1/app/importers/modular_importer.rb)
    This also resides inside the Zizia Gem. Here, the CSV is completely parsed into a single Rails object using the Gem's built-in parsing and importing tools. Each work parsed from the CSV is assigned to a `record` instance associated with the main Rails `importer` object. Each `record` has a deduplication key and relevant files attached to it, everything is saved, and then passed along. `Zizia::Importer#import` receives it next, which simply sends each record through to following procedure.
3. [`RecordImporter#import`](https://github.com/curationexperts/zizia/blob/v6.0.1/lib/zizia/record_importer.rb)
    This is where the handoff between Zizia and Hyrax takes place. Each `record` (future `CurateGenericWork` object) is passed as an argument to the `#create` method of `Hyrax.config.curation_concerns.first`, which in our application, translates to the `ActiveSupport::Concern` of `CurateGenericWork`. Now in Hyrax, the next process is initiated. 
4. [`Hyrax:Actors:CurateGenericWorkActor#create`](https://github.com/emory-libraries/dlp-curate/blob/main/app/actors/hyrax/actors/curate_generic_work_actor.rb)
    And we're now in the [Actor Stack](https://github.com/samvera/hyrax/blob/v3.4.2/app/services/hyrax/default_middleware_stack.rb). The `record` object that was created in Zizia now exists inside of the `env` object. All of the data will stay inside of `env` object, too--even as every Actor in the stack makes any necessary manipulations, additions, or deletions they need to in order to persist the whole Work in the ActiveFedora system.
    
    There are over a dozen Actors that operate in sequence, many of them using the Job classes that DLP has customized to fit its requirements. Below, a list of all Actors will be provided in the sequence that they start, making sure to mention any Jobs or Preservation Events that Actor may instigate. No explanation of what each Actor performs will be provided, though. Since the Actor Stack is the core of the Hyrax application, taking on any and all responsibility for the persistence of data, it is vitally important that all engineers do their own deep-dive into the code to form their own familiarity to it.

    If you do run into problems understanding why a customized Rack Middleware stack was utilized or how they fundamentally work, I recommend visiting this [link](https://samvera.github.io/actor_stack.html).
    - `PreservationEvent`s triggered here:
        - `Validation`
        - `Policy Assignment`
        - `File Submission`
5. [`Hyrax::Actors::OptimisticLockValidator`](https://github.com/samvera/hyrax/blob/v3.4.2/app/actors/hyrax/actors/optimistic_lock_validator.rb)
6. [`Hyrax::Actors::CreateWithRemoteFilesActor`](https://github.com/samvera/hyrax/blob/v3.4.2/app/actors/hyrax/actors/create_with_remote_files_actor.rb)
    - Actors this Actor may call:
        - [`Hyrax::Actors::FileSetActor`](https://github.com/emory-libraries/dlp-curate/blob/main/app/actors/hyrax/actors/file_set_actor.rb)(Hyrax Overwrite)
        - [`Hyrax::Actors::FileActor`](https://github.com/samvera/hyrax/blob/v3.4.2/app/actors/hyrax/actors/file_actor.rb)
    - Jobs this Actor may call:
        - [`IngestLocalFileJob`](https://github.com/samvera/hyrax/blob/v3.4.2/app/jobs/ingest_local_file_job.rb)
        - [`ImportUrlJob`](https://github.com/samvera/hyrax/blob/v3.4.2/app/jobs/import_url_job.rb)
        - [`VisibilityCopyJob`](https://github.com/samvera/hyrax/blob/v3.4.2/app/jobs/visibility_copy_job.rb)
        - [`InheritPermissionsJob`](https://github.com/samvera/hyrax/blob/v3.4.2/app/jobs/inherit_permissions_job.rb)
        - [`IngestJob`](https://github.com/samvera/hyrax/blob/v3.4.2/app/jobs/ingest_job.rb)
        - [`ContentNewVersionEventJob`](https://github.com/samvera/hyrax/blob/v3.4.2/app/jobs/content_new_version_event_job.rb)
        - [`CharacterizeJob`](https://github.com/emory-libraries/dlp-curate/blob/main/app/jobs/characterize_job.rb)(Hyrax Overwrite)
    - `PreservationEvent`s possibly triggered here:
        - `Virus Check`
        - `Message Digest Calculation`
        - `Characterization`
7. [`Hyrax::Actors::CreateWithFilesActor`](
https://github.com/samvera/hyrax/blob/v3.4.2/app/actors/hyrax/actors/create_with_files_actor.rb)
    - Actors this Actor may call:
        - [`Hyrax::Actors::FileSetActor`](https://github.com/emory-libraries/dlp-curate/blob/main/app/actors/hyrax/actors/file_set_actor.rb)(Hyrax Overwrite)
        - [`Hyrax::Actors::FileActor`](https://github.com/samvera/hyrax/blob/v3.4.2/app/actors/hyrax/actors/file_actor.rb)
    - Jobs this Actor may call:
        - [`AttachFilesToWorkJob`](https://github.com/emory-libraries/dlp-curate/blob/main/app/jobs/attach_files_to_work_job.rb)(Hyrax Overwrite)
        - [`IngestLocalFileJob`](https://github.com/samvera/hyrax/blob/v3.4.2/app/jobs/ingest_local_file_job.rb)
        - [`ImportUrlJob`](https://github.com/samvera/hyrax/blob/v3.4.2/app/jobs/import_url_job.rb)
        - [`VisibilityCopyJob`](https://github.com/samvera/hyrax/blob/v3.4.2/app/jobs/visibility_copy_job.rb)
        - [`InheritPermissionsJob`](https://github.com/samvera/hyrax/blob/v3.4.2/app/jobs/inherit_permissions_job.rb)
        - [`IngestJob`](https://github.com/samvera/hyrax/blob/v3.4.2/app/jobs/ingest_job.rb)
        - [`ContentNewVersionEventJob`](https://github.com/samvera/hyrax/blob/v3.4.2/app/jobs/content_new_version_event_job.rb)
        - [`CharacterizeJob`](https://github.com/emory-libraries/dlp-curate/blob/main/app/jobs/characterize_job.rb)(Hyrax Overwrite)
    - `PreservationEvent`s possibly triggered here:
        - `Virus Check`
        - `Message Digest Calculation`
        - `Characterization`
8. [`Hyrax::Actors::CollectionsMembershipActor`](https://github.com/samvera/hyrax/blob/v3.4.2/app/actors/hyrax/actors/collections_membership_actor.rb)
9. [`Hyrax::Actors::AddToWorkActor`](https://github.com/samvera/hyrax/blob/v3.4.2/app/actors/hyrax/actors/add_to_work_actor.rb)
10. [`Hyrax::Actors::AttachMembersActor`](https://github.com/samvera/hyrax/blob/v3.4.2/app/actors/hyrax/actors/attach_members_actor.rb)
11. [`Hyrax::Actors::ApplyOrderActor`](https://github.com/samvera/hyrax/blob/v3.4.2/app/actors/hyrax/actors/apply_order_actor.rb)
12. [`Hyrax::Actors::DefaultAdminSetActor`](https://github.com/samvera/hyrax/blob/v3.4.2/app/actors/hyrax/actors/default_admin_set_actor.rb)
13. [`Hyrax::Actors::InterpretVisibilityActor`](https://github.com/samvera/hyrax/blob/v3.4.2/app/actors/hyrax/actors/interpret_visibility_actor.rb)
14. [`Hyrax::Actors::TransferRequestActor`](https://github.com/samvera/hyrax/blob/v3.4.2/app/actors/hyrax/actors/transfer_request_actor.rb)
    - Jobs this Actor may call:
        - [`ContentDepositorChangeEventJob`](https://github.com/samvera/hyrax/blob/v3.4.2/app/jobs/content_depositor_change_event_job.rb)
15. [`Hyrax::Actors::ApplyPermissionTemplateActor`](https://github.com/samvera/hyrax/blob/v3.4.2/app/actors/hyrax/actors/apply_permission_template_actor.rb)
16. [`Hyrax::Actors::CleanupFileSetsActor`](https://github.com/samvera/hyrax/blob/v3.4.2/app/actors/hyrax/actors/cleanup_file_sets_actor.rb)
17. [`Hyrax::Actors::CleanupTrophiesActor`](https://github.com/samvera/hyrax/blob/v3.4.2/app/actors/hyrax/actors/cleanup_trophies_actor.rb)
18. [`Hyrax::Actors::FeaturedWorkActor`](https://github.com/samvera/hyrax/blob/v3.4.2/app/actors/hyrax/actors/featured_work_actor.rb)
19. [`Hyrax::Actors::ModelActor`](https://github.com/samvera/hyrax/blob/v3.4.2/app/actors/hyrax/actors/model_actor.rb)
20. [`Hyrax::Actors::InitializeWorkflowActor`](https://github.com/samvera/hyrax/blob/v3.4.2/app/actors/hyrax/actors/initialize_workflow_actor.rb)
## Preservation Events Quick Reference
The following are the types of Preservation Events the Curate application records and when/where they are created.
-   `Validation`: confirms that the submission package was validated.
    - Records:
        - `start`: date and time when the event started.
        - `outcome`: "Success"/"Failure"
        - `software_version`: "Curate v.1"
        - `user`: user that initiated bulk/single import.
        - `details`: "Submission package validated"
    - Event created in: `CurateGenericWorkActor`
-  `Policy Assignment`: establishes the visibility and access of the Work.
    - Records:
        - `start`: date and time when the event started.
        - `outcome`: "Success"/"Failure"
        - `software_version`: "Curate v.1"
        - `user`: user that initiated bulk/single import.
        - `details`: "Visibility/access controls assigned: < access status >"
    - Event created in: `CurateGenericWorkActor`
- `Characterization`: technical metadata extracted from file, format identified, and file validated.
    - Records:
        - `start`: date and time when the event started.
        - `outcome`: "Success"/"Failure"
        - `software_version`: "FITS v1.5.0"
        - `user`: user that deposited the file set.
        - `details`: "< file type >: < file name > - Technical metadata extracted from file, format identified, and file validated"
    - Event created in: `CharacterizeJob`
- `Fixity Check`: checks the integrity of a file.
    - Records:
        - `start`: date and time when the event started.
        - `outcome`: "Success"/"Failure"
        - `software_version`: "Fedora v4.7.6"
        - `user`: user that initiates the check.
        - `details`: either "Fixity intact for file: < file name >: sha1:< sha1 value >" or "Fixity check failed for: < file name >: sha1:< sha1 value >"
    - Event created in: `FixityCheckJob`
- `Virus Check`: checks a file for viruses.
    - Records:
        - `start`: date and time when the event started.
        - `outcome`: "Success"/"Failure"
        - `software_version`: "ClamAV 0.101.4"
        - `user`: user that deposited the file set.
        - `details`: either "No viruses found" or "Virus was found in file: < preservation master file name >"
    - Event created in: `FileSet#viruses?`
- `File Submission`: denotes the submission of a file for ingest.
    - Records:
        - `start`: date and time when the ingest started.
        - `outcome`: "Success"/"Failure"
        - `software_version`: "Fedora v4.7.6"
        - `user`: user that submitted the file.
        - `details`: either "< file name > submitted for preservation storage" or "< file name > could not be submitted for preservation storage"
    - Event created in: `JobIoWrapper#ingest_file`
- `Message Digest Calculation`: denotes the calculation of a file's checksum.
    - Records:
        - `start`: date and time when the calculation started.
        - `outcome`: "Success"/"Failure"
        - `software_version`: "FITS v1.5.0, Fedora v4.7.6, Ruby Digest library"
        - `user`: user that deposited the file.
        - `details`: an array of the checksums.
    - Event created in: `Hydra::Works::CharacterizationServic#append_original_checksum`