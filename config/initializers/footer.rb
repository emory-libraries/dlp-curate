# frozen_string_literal: true

GIT_SHA =
  if Rails.env.production? && File.exist?('/opt/dlp-curate/revisions.log')
    `tail -1 /opt/dlp-curate/revisions.log`.chomp.split(" ")[3].gsub(/\)$/, '')
  elsif Rails.env.development? || Rails.env.test?
    `git rev-parse HEAD`.chomp
  else
    "Unknown SHA"
  end

BRANCH =
  if Rails.env.production? && File.exist?('/opt/dlp-curate/revisions.log')
    `tail -1 /opt/dlp-curate/revisions.log`.chomp.split(" ")[1]
  elsif Rails.env.development? || Rails.env.test?
    `git rev-parse --abbrev-ref HEAD`.chomp
  else
    "Unknown branch"
  end

LAST_DEPLOYED =
  if Rails.env.production? && File.exist?('/opt/dlp-curate/revisions.log')
    deployed = `tail -1 /opt/dlp-curate/revisions.log`.chomp.split(" ")[7]
    Date.parse(deployed).strftime("%d %B %Y")
  else
    "Not in deployed environment"
  end
