# frozen_string_literal: true

class ApplicationController < ActionController::Base
  helper Openseadragon::OpenseadragonHelper
  # Deprecation Warning: As of Curate v3, Zizia and this helper call will be removed.
  helper Zizia::Engine.helpers
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Hydra::Controller::ControllerBehavior

  # Adds Hyrax behaviors into the application controller
  include Hyrax::Controller
  include Hyrax::ThemedLayoutController
  with_themed_layout '1_column'

  protect_from_forgery with: :exception
  before_action :authenticate_user!, except: [:uv_config, :resource_id_param, :default_config, :uv_config_liberal, :uv_config_liberal_low, :visibility_lookup]

  # GET /uv/config
  # Retrieve the UV configuration for a given resource
  def uv_config
    config = case visibility_lookup(resource_id_param)
             when 'open', 'authenticated'
               uv_config_liberal
             when 'emory_low'
               uv_config_liberal_low
             else
               default_config
             end

    respond_to do |format|
      format.json { render json: config }
    end
  end

  private

    def resource_id_param
      params[:id]
    end

    # Construct a UV configuration with the default options (conservative)
    # @return [UvConfiguration]
    def default_config
      UvConfiguration.new
    end

    # Construct a UV configuration with downloads and share enabled
    # @return [UvConfiguration]
    def uv_config_liberal
      UvConfiguration.new(
        modules: {
          footerPanel: {
            options: {
              shareEnabled:      true,
              downloadEnabled:   true,
              fullscreenEnabled: true
            }
          }
        }
      )
    end

    # Construct a UV configuration for emory_low visibility with downloads and share enabled,
    # and download dialogue options/content modifications
    # @return [UvConfiguration]
    def uv_config_liberal_low # rubocop:disable Metrics/MethodLength
      UvConfiguration.new(
        modules: {
          footerPanel:      {
            options: {
              shareEnabled:      true,
              downloadEnabled:   true,
              fullscreenEnabled: true
            }
          },
          downloadDialogue: {
            options: {
              currentViewDisabledPercentage: 0, # set to an unreasonably low value so that Current View option is hidden
              confinedImageSize:             100_000 # set to an unreasonably high value so that Whole Image Low Res option is hidden
            },
            content: {
              wholeImageHighRes: "Whole Image 400px"
            }
          }
        }
      )
    end # rubocop:enable Metrics/MethodLength

    def visibility_lookup(resource_id)
      return nil if resource_id.nil?
      response = Blacklight.default_index.connection.get 'select', params: { q: "id:#{resource_id}" }
      response["response"]["docs"].first["visibility_ssi"]
    end
end
