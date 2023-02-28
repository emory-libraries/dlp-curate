# frozen_string_literal: true

require 'fileutils'

desc "Compile all ArchivesSpace resources across all repositories in a .csv file"

# Command to run in the terminal: `nohup bundle exec rake compile_aspace_resources &`
# Task will run in the background. You can retrieve the `tmp/aspace/resources_report.csv` file after completion.
# You can verify completion in the `tmp/aspace/resources_report.log` file.

task compile_aspace_resources: :environment do
  start_time = Time.zone.now

  # Create aspace directory if it does not exist
  dir = Rails.root.join('tmp', 'aspace')
  FileUtils.mkdir_p(dir) unless File.directory?(dir)

  # Create/Empty files
  report_path = Rails.root.join('tmp', 'aspace', 'resources_report.csv')
  log_path = Rails.root.join('tmp', 'aspace', 'resources_report.log')
  File.open(report_path, "w") { |f| f.truncate(0) }
  File.open(log_path, "w") { |f| f.truncate(0) }

  # Generate Report

  File.open(log_path, "a+") { |f| f.write "ℹ️ LOGS - Compile all ArchivesSpace resources across all repositories in a .csv file\n" }

  begin
    # Add headers to csv file
    headers = [:ead_id, :repository_id, :repository_name, :resource_id, :title, :call_number, :ead_location, :aspace_url]
    CSV.open(report_path, "a+") { |csv| csv << headers.map(&:to_s) }

    # Fetch repositories
    client = Aspace::ReportsService.new.authenticate!
    repositories = client.fetch_repositories
    resources_count = 0

    repositories.each do |repository|
      repository_id = repository[:repository_id]
      repository_name = repository[:name]

      # Fetch last page in repository
      last_page = client.fetch_repository_last_page(repository_id: repository_id)

      # Iterate from first page to last
      (1..last_page).each do |page|
        File.open(log_path, "a+") { |f| f.write "🤖 Generating page #{page} of ArchivesSpace resources in repository ##{repository_id} (#{repository_name})\n" }

        # Fetch resources in corresponding page
        resources = client.fetch_resources_by_page(page, repository_id: repository_id)

        # Write resources to csv file
        CSV.open(report_path, "a+") do |csv|
          resources.each do |resource|
            row = [
              resource[:ead_id],
              repository[:repository_id],
              repository[:name],
              resource[:resource_id],
              resource[:title],
              resource[:call_number],
              resource[:ead_location],
              resource[:aspace_url]
            ]
            csv << row
          end
        end
        resources_count += resources.count
        File.open(log_path, "a+") { |f| f.write "✅ Generated page #{page} of ArchivesSpace resources in repository ##{repository_id} (#{repository_name})\n" }
      end
    end
    File.open(log_path, "a+") { |f| f.write "🏁 DONE - Finished generating #{resources_count} resources across #{repositories.count} repositories. Refer to file `#{report_path}`.\n" }
  rescue => e
    File.open(log_path, "a+") { |f| f.write "🚨 ERROR - REPORT FAILED TO GENERATE: #{e.message}\n" }
  end

  duration = (Time.zone.now - start_time).to_i
  File.open(log_path, "a+") { |f| f.write "⏱️ DURATION - #{duration / 60} minute(s), #{duration % 60} second(s).\n" }
end
