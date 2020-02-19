# frozen_string_literal: true

class CurateNoid < Noid::Rails::Service
  def mint
    loop do
      pid = super + Rails.configuration.x.curate_template
      return pid unless identifier_in_use?(pid)
    end
  end

  private

    def identifier_in_use?(pid)
      ActiveFedora::Base.exists?(pid) || ActiveFedora::Base.gone?(pid)
    end
end
