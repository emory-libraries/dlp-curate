# frozen_string_literal: true

class AwsFixityEvent
  attr_reader :sha1, :fixity_start

  def initialize(line)
    @sha1 = line['event_sha1']&.strip
    @aws_bucket = line['event_bucket']&.strip
    @fixity_start = line['event_start']&.strip
    @fixity_end = line['event_end']&.strip
    @event_type = line['event_type']&.strip || 'Fixity Check'
    @user = line['initiating_user']&.strip || 'AWS Serverless Fixity'
    @outcome = line['outcome']&.strip
    @software_version = line['software_version']&.strip || 'Serverless Fixity v1.0'
    @details_outcome = @outcome == 'Failure' || @outcome.blank? ? 'check failed' : 'intact'
  end

  def process_event
    { 'type' => @event_type, 'start' => @fixity_start, 'end' => @fixity_end,
      'details' => "Fixity #{@details_outcome} for sha1:#{@sha1} in #{@aws_bucket}",
      'software_version' => @software_version, 'user' => @user, 'outcome' => @outcome }
  end
end
