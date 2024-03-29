# frozen_string_literal: true

Hyrax.config do |config|
  # Injected via `rails g hyrax:work CurateGenericWork`
  config.register_curation_concern :curate_generic_work
  # Register roles that are expected by your implementation.
  # @see Hyrax::RoleRegistry for additional details.
  # @note there are magical roles as defined in Hyrax::RoleRegistry::MAGIC_ROLES
  # config.register_roles do |registry|
  #   registry.add(name: 'captaining', description: 'For those that really like the front lines')
  # end

  config.admin_set_model = 'AdminSet'
  config.collection_model = '::Collection'

  # When an admin set is created, we need to activate a workflow.
  # The :default_active_workflow_name is the name of the workflow we will activate.
  # @see Hyrax::Configuration for additional details and defaults.
  # config.default_active_workflow_name = 'default'

  # Which RDF term should be used to relate objects to an admin set?
  # If this is a new repository, you may want to set a custom predicate term here to
  # avoid clashes if you plan to use the default (dct:isPartOf) for other relations.
  # config.admin_set_predicate = ::RDF::DC.isPartOf

  # Which RDF term should be used to relate objects to a rendering?
  # If this is a new repository, you may want to set a custom predicate term here to
  # avoid clashes if you plan to use the default (dct:hasFormat) for other relations.
  # config.rendering_predicate = ::RDF::DC.hasFormat

  # Email recipient of messages sent via the contact form
  # config.contact_email = "repo-admin@example.org"

  # Text prefacing the subject entered in the contact form
  # config.subject_prefix = "Contact form:"

  # How many notifications should be displayed on the dashboard
  # config.max_notifications_for_dashboard = 5

  # How frequently should a file be fixity checked
  config.max_days_between_fixity_checks = 1

  # Options to control the file uploader
  config.uploader = {
    limitConcurrentUploads: 6,
    maxNumberOfFiles:       100,
    maxFileSize:            2500.megabytes
  }

  # Enable displaying usage statistics in the UI
  # Defaults to false
  # Requires a Google Analytics id and OAuth2 keyfile.  See README for more info
  # config.analytics = false

  # Google Analytics tracking ID to gather usage statistics
  # config.google_analytics_id = 'UA-99999999-1'

  # Date you wish to start collecting Google Analytic statistics for
  # Leaving it blank will set the start date to when ever the file was uploaded by
  # NOTE: if you have always sent analytics to GA for downloads and page views leave this commented out
  # config.analytic_start_date = DateTime.new(2014, 9, 10)

  # Enables a link to the citations page for a work
  # Default is false
  # config.citations = false

  # Where to store tempfiles, leave blank for the system temp directory (e.g. /tmp)
  # config.temp_file_base = '/home/developer1'

  # Hostpath to be used in Endnote exports
  # config.persistent_hostpath = 'http://localhost/files/'

  # If you have ffmpeg installed and want to transcode audio and video set to true
  # config.enable_ffmpeg = false

  # Hyrax uses NOIDs for files and collections instead of Fedora UUIDs
  # where NOID = 10-character string and UUID = 32-character string w/ hyphens
  # config.enable_noids = true

  # Template for your repository's NOID IDs
  config.noid_template = ".rdddeeeeeee"
  # Use the database-backed minter class
  config.noid_minter_class = Noid::Rails::Minter::Db

  # Store identifier minter's state in a file for later replayability
  # config.minter_statefile = '/tmp/minter-state'

  # Prefix for Redis keys
  # config.redis_namespace = "hyrax"

  # Path to the file characterization tool
  # config.fits_path = "fits.sh"

  # Path to the file derivatives creation tool
  # config.libreoffice_path = "soffice"

  # Option to enable/disable full text extraction from PDFs
  # Default is true, set to false to disable full text extraction
  config.extract_full_text = false

  # How many seconds back from the current time that we should show by default of the user's activity on the user's dashboard
  # config.activity_to_show_default_seconds_since_now = 24*60*60

  # Hyrax can integrate with Zotero's Arkivo service for automatic deposit
  # of Zotero-managed research items.
  # config.arkivo_api = false

  # Stream realtime notifications to users in the browser
  config.realtime_notifications = false

  # Location autocomplete uses geonames to search for named regions
  # Username for connecting to geonames
  # config.geonames_username = ''

  # Should the acceptance of the licence agreement be active (checkbox), or
  # implied when the save button is pressed? Set to true for active
  # The default is true.
  # config.active_deposit_agreement_acceptance = true

  # Should work creation require file upload, or can a work be created first
  # and a file added at a later time?
  # The default is true.
  # config.work_requires_files = true

  # How many rows of items should appear on the work show view?
  # The default is 10
  # config.show_work_item_rows = 10

  # Enable IIIF image service. This is required to use the
  # IIIF viewer enabled show page
  #
  # If you have run the riiif generator, an embedded riiif service
  # will be used to deliver images via IIIF. If you have not, you will
  # need to configure the following other configuration values to work
  # with your image server:
  #
  #   * iiif_image_url_builder
  #   * iiif_info_url_builder
  #   * iiif_image_compliance_level_uri
  #   * iiif_image_size_default
  #
  # Default is false
  config.iiif_image_server = true

  # If we have an external IIIF server, use it for image requests; else, use riiif
  config.iiif_image_url_builder = lambda do |file_id, base_url, size|
    builder_service = IiifUrlBuilderService.new(file_set_id: file_id, size: size)
    if ENV['IIIF_SERVER_URL'].present?
      iiif_url = if ENV.fetch('FEDORA_ADAPTER', 'default') == 's3' ||
                    ENV.fetch('FEDORA_ADAPTER', 'default') == 'S3'
                   builder_service.sha1_url
                 else
                   builder_service.file_set_id_url
                 end
      Rails.logger.debug "event: iiif_image_request: #{iiif_url}"
      iiif_url
    else
      Riiif::Engine.routes.url_helpers.image_url(file_id, host: base_url, size: size)
    end
  end

  # If we have an external IIIF server, use it for info.json; else, use riiif
  config.iiif_info_url_builder = lambda do |file_id, base_url|
    builder_service = IiifUrlBuilderService.new(file_set_id: file_id, size: '')
    if ENV['IIIF_SERVER_URL'].present?
      iiif_info_url = if ENV.fetch('FEDORA_ADAPTER', 'default') == 's3' ||
                         ENV.fetch('FEDORA_ADAPTER', 'default') == 'S3'
                        builder_service.sha1_info_url
                      else
                        builder_service.file_id_info_url
                      end
      Rails.logger.debug "event: iiif_info_request: #{iiif_info_url}"
      iiif_info_url
    else
      uri = Riiif::Engine.routes.url_helpers.info_url(file_id, host: base_url)
      uri.sub(%r{/info\.json\Z}, '')
    end
  end

  # config.iiif_info_url_builder = lambda do |_, _|
  #   ""
  # end

  # Returns a URL that indicates your IIIF image server compliance level
  # config.iiif_image_compliance_level_uri = 'http://iiif.io/api/image/2/level2.json'

  # Returns a IIIF image size default
  # config.iiif_image_size_default = '600,'

  # Fields to display in the IIIF metadata section; default is the required fields
  # config.iiif_metadata_fields = Hyrax::Forms::WorkForm.required_fields

  # Should a button with "Share my work" show on the front page to all users (even those not logged in)?
  # config.display_share_button_when_not_logged_in = true

  # The user who runs batch jobs. Update this if you aren't using emails
  config.batch_user_key = 'batchuser'

  # The user who runs fixity check jobs. Update this if you aren't using emails
  config.audit_user_key = 'audituser'
  #
  # The banner image. Should be 5000px wide by 1000px tall
  # config.banner_image = 'https://cloud.githubusercontent.com/assets/92044/18370978/88ecac20-75f6-11e6-8399-6536640ef695.jpg'

  # Temporary paths to hold uploads before they are ingested into FCrepo
  # These must be lambdas that return a Pathname. Can be configured separately
  config.upload_path = ->() { ENV['UPLOAD_PATH'] || Rails.root + 'tmp' + 'uploads' }
  config.cache_path = ->() { ENV['CACHE_PATH'] || Rails.root + 'tmp' + 'uploads' + 'cache' }

  # Location on local file system where derivatives will be stored
  # If you use a multi-server architecture, this MUST be a shared volume
  config.derivatives_path = ENV['DERIVATIVES_PATH'] || Rails.root.join('tmp', 'derivatives')

  # Location where collection banner images will be saved after upload
  config.branding_path = ENV['BRANDING_PATH'] || Rails.root.join('public', 'branding')

  # Should schema.org microdata be displayed?
  # config.display_microdata = true

  # What default microdata type should be used if a more appropriate
  # type can not be found in the locale file?
  # config.microdata_default_type = 'http://schema.org/CreativeWork'

  # Location on local file system where uploaded files will be staged
  # prior to being ingested into the repository or having derivatives generated.
  # If you use a multi-server architecture, this MUST be a shared volume.
  config.working_path = ENV['WORKING_PATH'] || Rails.root.join('tmp', 'uploads')

  # Should the media display partial render a download link?
  # config.display_media_download_link = true

  # A configuration point for changing the behavior of the license service
  #   @see Hyrax::LicenseService for implementation details
  # config.license_service_class = Hyrax::LicenseService

  # Labels for display of permission levels
  # config.permission_levels = { "View/Download" => "read", "Edit access" => "edit" }

  # Labels for permission level options used in dropdown menus
  # config.permission_options = { "Choose Access" => "none", "View/Download" => "read", "Edit" => "edit" }

  # Labels for owner permission levels
  # config.owner_permission_levels = { "Edit Access" => "edit" }

  # Path to the ffmpeg tool
  # config.ffmpeg_path = 'ffmpeg'

  # Max length of FITS messages to display in UI
  # config.fits_message_length = 5

  # ActiveJob queue to handle ingest-like jobs
  # config.ingest_queue_name = :default

  ## Attributes for the lock manager which ensures a single process/thread is mutating a ore:Aggregation at once.
  # How many times to retry to acquire the lock before raising UnableToAcquireLockError
  # config.lock_retry_count = 600 # Up to 2 minutes of trying at intervals up to 200ms
  #
  # Maximum wait time in milliseconds before retrying. Wait time is a random value between 0 and retry_delay.
  config.lock_retry_delay = 2_000
  #
  # How long to hold the lock in milliseconds
  config.lock_time_to_live = 240_000

  ## Do not alter unless you understand how ActiveFedora handles URI/ID translation
  # config.translate_id_to_uri = lambda do |uri|
  #                                baseparts = 2 + [(Noid::Rails::Config.template.gsub(/\.[rsz]/, '').length.to_f / 2).ceil, 4].min
  #                                uri.to_s.sub(baseurl, '').split('/', baseparts).last
  #                              end
  # config.translate_uri_to_id = lambda do |id|
  #                                "#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}/#{Noid::Rails.treeify(id)}"
  #                              end

  ## Fedora import/export tool
  #
  # Path to the Fedora import export tool jar file
  # config.import_export_jar_file_path = "tmp/fcrepo-import-export.jar"
  #
  # Location where BagIt files should be exported
  # config.bagit_dir = "tmp/descriptions"

  config.browse_everything = nil

  ## Whitelist all directories which can be used to ingest from the local file
  # system.
  #
  # Any file, and only those, that is anywhere under one of the specified
  # directories can be used by CreateWithRemoteFilesActor to add local files
  # to works. Files uploaded by the user are handled separately and the
  # temporary directory for those need not be included here.
  #
  # Default value includes BrowseEverything.config['file_system'][:home] if it
  # is set, otherwise default is an empty list. You should only need to change
  # this if you have custom ingestions using CreateWithRemoteFilesActor to
  # ingest files from the file system that are not part of the BrowseEverything
  # mount point.
  #
  # config.whitelisted_ingest_dirs = []
end

Date::DATE_FORMATS[:standard] = "%m/%d/%Y"

Qa::Authorities::Local.register_subauthority('subjects', 'Qa::Authorities::Local::TableBasedAuthority')
Qa::Authorities::Local.register_subauthority('languages', 'Qa::Authorities::Local::TableBasedAuthority')
Qa::Authorities::Local.register_subauthority('genres', 'Qa::Authorities::Local::TableBasedAuthority')

# Geonames username
Qa::Authorities::Geonames.username = ENV['GEONAMES_USERNAME']

# set bulkrax default work type to first curation_concern if it isn't already set

Bulkrax.default_work_type = Hyrax.config.curation_concerns.first.to_s if Bulkrax.default_work_type.blank?

Hyrax::CollectionSearchBuilder.class_eval do
  # Hyrax v3.4.2 override: solr_parameters[:sort], previously, was always set by
  #   "#{sort_field} asc", because the sort command is never called.
  # Sort results by title if no query was supplied.
  # This overrides the default 'relevance' sort.
  def add_sorting_to_solr(solr_parameters)
    return if solr_parameters[:q]
    solr_parameters[:sort] = sort || "#{sort_field} asc"
  end
end
