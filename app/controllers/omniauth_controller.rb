# frozen_string_literal: true

class OmniauthController < Devise::SessionsController
  def new
    # Rails.logger.debug "SessionsController#new: request.referer = #{request.referer}"
    if Rails.env.production?
      redirect_post(user_shibboleth_omniauth_authorize_path, options: { authenticity_token: :auto })
    else
      super
    end
  end
end
