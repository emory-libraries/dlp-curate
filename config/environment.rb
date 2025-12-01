# frozen_string_literal: true

# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!
Rails.logger.datetime_format = "%Y-%m-%d %H:%M:%S"
Rails.logger.level = Logger::INFO

# Remove the existing visibility label constant
Hyrax::PermissionBadge.send(:remove_const, :VISIBILITY_LABEL_CLASS)
Hyrax::PermissionBadge::VISIBILITY_LABEL_CLASS = {
  authenticated: "badge-info",
  embargo:       "badge-warning",
  lease:         "badge-warning",
  open:          "badge-success",
  restricted:    "badge-danger",
  low_res:       "badge-success",
  emory_low:     "badge-info",
  rose_high:     "badge-warning"
}.freeze
