# frozen_string_literal: true

class Ability
  include Hydra::Ability
  include Hyrax::Ability
  self.ability_logic += [:everyone_can_create_curation_concerns]

  def can_import_works?
    admin?
  end

  def can_export_works?
    admin?
  end

  # Define any customized permissions here.
  def custom_permissions
    # Limits deleting objects to a the admin user
    #
    # if current_user.admin?
    #   can [:destroy], ActiveFedora::Base
    # end
    return unless current_user.admin?

    can [:create, :show, :add_user, :remove_user, :index, :edit, :update, :destroy], Role

    # Deprecation Warning: As of Curate v3, Zizia and these abilities will be removed.
    can :manage, Zizia::CsvImport
    can :manage, Zizia::CsvImportDetail
    can :manage, :archivesspace

    # Limits creating new objects to a specific group
    #
    # if user_groups.include? 'special_group'
    #   can [:create], ActiveFedora::Base
    # end
  end
end
