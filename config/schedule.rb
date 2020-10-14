# frozen_string_literal: true

# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

case @hostname
when 'curate-test'
  # run rake task on 18th every three months
  every '0 0 18 */3 *' do
    rake "curate:file_sets:fixity_check"
  end
when 'curate-prod'
  # run rake task on 18th every two months
  every '0 0 18 */2 *' do
    rake "curate:file_sets:fixity_check"
  end
end
