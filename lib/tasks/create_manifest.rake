# frozen_string_literal: true
require 'iiif_manifest'

namespace :curate do
  namespace :works do
    desc "Create manifest for work and save them"
    task create_manifest: :environment do
      work = ENV['work']
      if work.present?
        CreateManifest.process(work)
      else
        CreateManifest.process
      end
    end
  end
end
