# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!
Rails.logger.datetime_format = "%Y-%m-%d %H:%M:%S"
Rails.logger.level = Logger::INFO

# Remove the existing visibility label constant
Hyrax::PermissionBadge.send(:remove_const, :VISIBILITY_LABEL_CLASS)
Hyrax::PermissionBadge::VISIBILITY_LABEL_CLASS = {
  authenticated: "label-info",
  embargo: "label-warning",
  lease: "label-warning",
  open: "label-success",
  restricted: "label-danger",
  low_res: "label-success",
  emory_low: "label-info",
  rose_high: "label-warning"
}.freeze
