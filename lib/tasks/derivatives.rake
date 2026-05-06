# frozen_string_literal: true
namespace :derivatives do
  desc "Regenerate derivatives for all works"
  task regenerate_all: :environment do
    work_docs = Hyrax::SolrService.query("has_model_ssim:CurateGenericWork", rows: 1_000_000, fl: "id")
    total = 0

    work_docs.each do |doc|
      work = find_work(doc["id"])
      regenerate_derivatives(work)
      total += 1
    end

    puts "Queued jobs to regenerate derivatives for #{total} work(s)"
  end

  desc "Regenerate derivatives for a single work, e.g. rake derivatives:regenerate['c821gj76b']"
  task :regenerate, [:id] => :environment do |_task, args|
    id = args[:id]
    abort "ERROR: no work id specified, aborting" unless id

    results = Hyrax::SolrService.query("id:#{id}", rows: 1)
    abort "ERROR: cannot find work with id #{id}, aborting" if results.blank?

    work = find_work(id)
    regenerate_derivatives(work)
    puts "Queued background jobs to regenerate derivatives for record: #{id}"
  end

  def find_work(id)
    if Hyrax.config.valkyrie_transition?
      Hyrax.query_service.find_by(id:)
    else
      CurateGenericWork.find(id)
    end
  end

  def regenerate_derivatives(work)
    case work
    when Hyrax::Resource
      regenerate_valkyrie_derivatives(work)
    else
      regenerate_af_derivatives(work)
    end
  end

  def regenerate_af_derivatives(work)
    work.file_sets.each do |fs|
      puts " processing FileSet #{fs.id}"
      asset_path = fs.original_file.uri.to_s
      asset_path = asset_path[asset_path.index(fs.id.to_s)..-1]
      CreateDerivativesJob.perform_later(fs, asset_path)
    end
  end

  def regenerate_valkyrie_derivatives(work)
    file_sets = Hyrax.custom_queries.find_child_file_sets(resource: work)
    file_sets.each do |fs|
      puts " processing FileSet #{fs.id}"
      fm = Hyrax.custom_queries
                .find_many_file_metadata_by_use(resource: fs, use: Hyrax::FileMetadata::Use::ORIGINAL_FILE)
                .first
      next unless fm

      Hyrax.publisher.publish('file.characterized',
                              file_set:  fs,
                              file_id:   fm.id.to_s,
                              path_hint: fm.file_identifier.to_s)
    end
  end
end
