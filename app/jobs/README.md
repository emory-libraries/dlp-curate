# Ingestion Processes Tutorial
## Reference Materials
The following sites were key in shedding light on internal Samvera processes that are the backbone of DLP's customizations. 
- [Samvera's homepage](https://samvera.github.io/index.html)
## To Better Understand Hyrax
The creation of curation objects inside of Hyrax depends upon a custom-built [Rack Middleware Stack](https://guides.rubyonrails.org/rails_on_rack.html). In essence, it is a coding design pattern that establishes an environment object, which is passed from Actor to Actor. The [custom stack's Actors](https://github.com/samvera/hyrax/blob/v3.0.0.pre.rc1/app/services/hyrax/default_middleware_stack.rb) each have a responsibility to either verify, groom, persist, associate, guard, or clean up, all while logging the success/failure of each operation. Some processes actually start and end in the middle of this stack, while others have to rearrange or inject custom Actors to operate properly.  

For an example of how the stack works, visit this [link](https://samvera.github.io/what-happens-deposit-2.0.html) to see how Hyrax ingests a Work out-of-the-box. The Digital Library Program' Curate application has overridden and customized many of Hyrax' [Actors](https://github.com/emory-libraries/dlp-curate/tree/main/app/actors/hyrax/actors) and associated [Jobs](https://github.com/emory-libraries/dlp-curate/tree/main/app/jobs) to accomplish additional documentation of Preservation Events and other needed features. Below are some of the customizations.
## Actors
### [CurateGenericWorkActor](https://github.com/emory-libraries/dlp-curate/blob/main/app/actors/hyrax/actors/curate_generic_work_actor.rb)
This is the model actor for every curation piece we ingest. Notice the comment line stating that this Actor was automatically created by a Rails generator action. That's because Hyrax allows flexibility with the naming convention of the Generic Work Model.
This Actor inherits its methods from Hyrax' [BaseActor](https://github.com/samvera/hyrax/blob/v3.0.0.pre.rc1/app/actors/hyrax/actors/base_actor.rb), although two of the methods needed revisions to add needed functionality:
- `#create`: because DLP's Digital Collections is a digital archive intended to house all works indefinitely, preservation documentation is extremely important. Every event of creation or modification needs to persist alongside the work and its materials. The creation of any work coincides with the initiation of two `PreservationEvent` objects. One for the `Work`'s creation and the other for the establishment of its access control policy.
- `#apply_save_data_to_curation_concern`: this method, called within the `#create` command, applies the attributes assigned to the environment object (`env`) to the associated `curation_concern` after properly formatting those attributes. 
    - Since, by design, certain `CurateGenericWork`s have no metadata associated, the assigning of metadata can be skipped to save time. Those `Work`s will have an "skip_metadata" attribute passed along, triggering that skip.
    - In the process of adding `PreservationEvent`s to the `curation_concern`, software engineering found that, since `preservation_events` is a nested attribute, purely passing along an array of objects to the ActiveFedora system wouldn't work. [This block](https://github.com/emory-libraries/dlp-curate/blob/0f5f99a3091749fb262dbdbffae087e573eb19d8/app/actors/hyrax/actors/curate_generic_work_actor.rb#L24) was needed to push those nested objects into Fedora object. 

### [FileSetActor](https://github.com/emory-libraries/dlp-curate/blob/main/app/actors/hyrax/actors/file_set_actor.rb)
This is an overwrite of Hyrax' [FileSetActor](https://github.com/samvera/hyrax/blob/v3.0.0.pre.rc1/app/actors/hyrax/actors/file_set_actor.rb). This actor attaches `FileSet`s to a `CurateGenericWork`. Changes that were needed are: 
- `#create_content`, `#update_content`, and `#wrapper!`: a customized `FileSet` model was utilized, needing a different default `relation` argument set, as well as accepting a newly created argument (`preferred`) that denotes whether a file should be the first piece a user sees.
- `#create_metadata`: a new argument (`fileset_use`) was needed to distinguish how the file was to be used. This argument is passed into the `FileSet`'s Fedora object as the `pcdm_use` attribute.
- `#attach_to_work`: passing this `file_set` into `work.ordered_members` is omitted because the `ordered_members` association is not utilized in this Actor, but rather in its Job relative.
- `#fileset_name`: this method was added as a convenience when this Actor is used in other Jobs and RSpec. It makes assigning `FileSet`'s `label`s and `title`s easier.
## Jobs
### [AttachFilesToWorkJob](https://github.com/emory-libraries/dlp-curate/blob/main/app/jobs/attach_files_to_work_job.rb)
This is an overwrite of Hyrax' [AttachFilesToWorkJob](https://github.com/samvera/hyrax/blob/v3.0.0.pre.rc1/app/jobs/attach_files_to_work_job.rb). The Job invokes the `FileSetActor` class so that the Actor is available out of the constraints of the Middleware Stack. The following changes were necessary for this Actor.
- `#process_fileset`: `AttachFilesToWorkJob` had to accept multiple files into one `FileSet`, which Hyrax is not ready for out-of-the-box. This method was created so that multiple types of files could get attached, as well as the `preferred` attribute assigned.
- `#perform`: the metadata and content creation methods have been moved to the `process_fileset` command which is called here.
- `#preferred_file`: provides logic for which file is deemed the preferred item.
### [CharacterizeJob](https://github.com/emory-libraries/dlp-curate/blob/main/app/jobs/characterize_job.rb)
This is an overwrite of Hyrax' [CharacterizeJob](https://github.com/samvera/hyrax/blob/v3.0.0.pre.rc1/app/jobs/characterize_job.rb). This Job analyzes and provides details about a file attached to a `FileSet`. The needed changes are:
- `#perform`: The `#characterize` private method has been eliminated and rolled into this method. `PreservationEvents` has been included and the event of the file characterization has been recorded onto the work. The `CreateDerivativesJob.perform_later` call has been removed since `FileSetActor` takes care of that processing.
### [CreateDerivativesJob](https://github.com/emory-libraries/dlp-curate/blob/main/app/jobs/create_derivatives_job.rb)
This is an overwrite of Hyrax' [CreateDerivativesJob](https://github.com/samvera/hyrax/blob/v3.0.0.pre.rc1/app/jobs/create_derivatives_job.rb). This Job creates a Thumbnail from the image passed to it. The following are the changes made to the Hyrax version:
- `#perform`: The generation of thumbnails using MiniMagick has proven problematic and the addition of error logging has been implemented because of it.
