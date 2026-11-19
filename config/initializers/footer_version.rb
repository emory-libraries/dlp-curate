# frozen_string_literal: true

# CONGRATS! you got this file as part of the emory/EULM footer gem package. it's supposed to be here!
# If you want to make changes to the file, make sure to also rename it so that it doesn't get accidentally rewritten with gem updates.

# if you can figure out the path to the revision log from where the app is running...
# REVISIONS_LOGFILE = Rails.root.join("/opt", "#{ENV['PROJECT_NAME']}", "revisions.log")
REVISIONS_LOGFILE = Rails.root.join("..", "..", "revisions.log").cleanpath
GIT_LOGFILE = Rails.root.join(".git")

GIT_SHA =
  if File.exist?(REVISIONS_LOGFILE)
    `tail -1 #{REVISIONS_LOGFILE}`.chomp.split(" ")[3].gsub(/\)$/, "")
  elsif File.exist?(GIT_LOGFILE)
    `git rev-parse HEAD`.chomp
  else
    'Current release'
  end

BRANCH =
  if File.exist?(REVISIONS_LOGFILE)
    `tail -1 #{REVISIONS_LOGFILE}`.chomp.split(" ")[1]
  elsif File.exist?(GIT_LOGFILE)
    `git rev-parse --abbrev-ref HEAD`.chomp
  else
    # trying `pwd` here might give you a clue for the revisions.log path in a deployed env.
    `current`
  end

LAST_DEPLOYED =
  if File.exist?(REVISIONS_LOGFILE)
    deployed = `tail -1 #{REVISIONS_LOGFILE}`.chomp.split(" ")[7]
    Date.parse(deployed).strftime("%d %B %Y")
  elsif File.exist?(GIT_LOGFILE)
    `git log -1 --format=%cd --date=short`.chomp
  else
    Date.current.year
  end
