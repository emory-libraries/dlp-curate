# frozen_string_literal: true

class User < ApplicationRecord
  # Connects this user object to Hydra behaviors.
  include Hydra::User
  # Connects this user object to Role-management behaviors.
  include Hydra::RoleManagement::UserRoles

  # Connects this user object to Hyrax behaviors.
  include Hyrax::User
  include Hyrax::UserUsageStats

  class NilShibbolethUserError < RuntimeError
    attr_accessor :auth

    def initialize(message = nil, auth = nil)
      super(message)
      self.auth = auth
    end
  end

  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  # remove :database_authenticatable in production, remove :validatable to integrate with Shibboleth
  devise_modules = [:omniauthable, :rememberable, :trackable, omniauth_providers: [:shibboleth], authentication_keys: [:uid]]
  devise_modules.prepend(:database_authenticatable) if AuthConfig.use_database_auth?
  devise(*devise_modules)

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end

  # Groups include roles and those set by #groups= (especially in specs)
  def groups
    g = roles.map(&:name)
    g += group_service.fetch_groups(user: self)
    g
  end

  def viewer?
    roles.any? { |r| r.name.include? "viewer" }
  end

  # When a user authenticates via shibboleth, find their User object or make
  # a new one. Populate it with data we get from shibboleth.
  # @param [OmniAuth::AuthHash] auth
  def self.from_omniauth(auth)
    begin
      user = find_by!(provider: auth.provider, uid: auth.info.uid)
    rescue ActiveRecord::RecordNotFound
      log_omniauth_error(auth)
      return User.new
    end
    user.assign_attributes(display_name: auth.info.display_name, ppid: auth.uid)
    # tezprox@emory.edu isn't a real email address
    user.email = auth.info.uid + '@emory.edu' unless auth.info.uid == 'tezprox'
    user.save
    user
  end

  def self.log_omniauth_error(auth)
    if auth.info.uid.empty?
      Rails.logger.error "Nil user detected: Shibboleth didn't pass a uid for #{auth.inspect}"
    else
      # Log unauthorized logins to error.
      Rails.logger.error "Unauthorized user attemped login: #{auth.inspect}"
    end
  end
end

# Override a Hyrax class that expects to create system users with passwords.
# Since in production we're using shibboleth, and this removes the password
# methods from the User model, we need to override it.
module Hyrax::User
  module ClassMethods
    def find_or_create_system_user(user_key)
      u = ::User.find_or_create_by(uid: user_key)
      u.display_name = user_key
      u.email = "#{user_key}@example.com"
      u.password = ('a'..'z').to_a.shuffle(random: Random.new).join if AuthConfig.use_database_auth?
      u.save
      u
    end
  end
end
