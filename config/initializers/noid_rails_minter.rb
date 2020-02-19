# frozen_string_literal: true

Noid::Rails::Minter::Base.class_eval do
  def mint
    Mutex.new.synchronize do
      loop do
        pid = next_id + Rails.configuration.x.curate_template
        return pid unless identifier_in_use?(pid)
      end
    end
  end
end
