# frozen_string_literal: true
class ManifestAbility
  include CanCan::Ability

  def initialize
    can :read, :all
  end
end
