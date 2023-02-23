# frozen_string_literal: true
namespace :curate do
  desc "Marks busy jobs in Sidekiq queue for cancellation"
  task set_busy_jobs_to_cancel: :environment do
    job_id_array = ENV['job_ids']&.split(' ')

    if job_id_array.present?
      result = process_cancellations(job_id_array)
    else
      abort "ERROR: You must pass a string of ids separated by a space."
    end

    if result == true
      successful_cancellation
    else
      announce_unprocessed_ids(result)
    end
  end
end

def process_cancellations(job_id_array)
  return true if cancelled?(job_id_array) == true
  job_id_array.each { |id| cancel!(id) }
  cancelled?(job_id_array)
end

def cancelled?(job_id_array)
  return true if job_id_array.all? { |id| Sidekiq.redis { |c| c.exists?("cancelled-#{id}") } }
  job_id_array.select { |id| Sidekiq.redis { |c| !c.exists?("cancelled-#{id}") } }
end

def cancel!(jid)
  Sidekiq.redis { |c| c.setex("cancelled-#{jid}", 86_400, 1) }
end

def successful_cancellation
  puts <<~HEREDOC
    The ids provided were successfully cancelled.

    To have the cancellation take effect, please restart this environment's Sidekiq instance.
  HEREDOC
end

def announce_unprocessed_ids(unprocessed_ids)
  puts <<~HEREDOC
    The following id(s) didn't process correctly: #{unprocessed_ids.join(', ')}.

    This may be due to the processing of these ids taking longer
    than expected. Try running this process again with the ids
    listed above. If they've been processed correctly, you will
    receive a message saying so.

    Processing may not have been successful because this code could
    not find the job with the id(s) you provided. Please restart
    Sidekiq and verify any Job ids still running and try this again.
  HEREDOC
end
