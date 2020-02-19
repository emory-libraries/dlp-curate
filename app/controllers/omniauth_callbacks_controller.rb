# frozen_string_literal: true

class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def shibboleth
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in @user
      # This will help the user go back to where they came.
      # Refer: https://github.com/omniauth/omniauth/wiki/Saving-User-Location
      redirect_to request.env["omniauth.origin"] || hyrax.dashboard_path
      set_flash_message(:notice, :success, kind: "Shibboleth")
    else
      redirect_to root_path
      set_flash_message(:notice, :failure, kind: "Shibboleth", reason: "you aren't authorized to use this application.")
    end
  end
end
