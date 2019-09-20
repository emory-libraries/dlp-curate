# frozen_string_literal: true
# Setup up user groups and add users to those groups
require 'yaml'

class UserSetup
  attr_accessor :users_config

  # Set up the parameters for
  # @param [String] users_config a file containing the NetIDs of users in a group
  def initialize(users_config, log_location = STDOUT)
    raise "File #{users_config} does not exist" unless File.exist?(users_config)
    @users_config = YAML.safe_load(File.read(users_config))
    @user_group = users_config.split("/")[-1].remove!(".yml")
    @logger = Logger.new(log_location)
    @logger.level = Logger::DEBUG
    @logger.info "Initializing new user setup with users file #{users_config}"
  end

  # load users in a group
  def setup
    load_users
  end

  # Create the user role (it is the name of the file), or find it if it exists already
  # @return [Role] the user Role
  def user_role
    Role.find_or_create_by(name: @user_group)
  end

  # Adds users from the yaml file to the given user_group
  def load_users
    # user_role.users = []
    # user_role.save
    @users_config.each_key do |provider|
      @users_config[provider].each do |a|
        add_user(a, provider)
      end
    end
  end

  # Add user to specific group
  # @param [String] the uid of the user
  # @return [User] the user who was just added to the group
  def add_user(uid, provider = "database")
    user = ::User.find_by(provider: provider, uid: uid)
    user = create_user(uid, provider) if user.nil?
    add_user_to_group(uid, user) unless user_role.users.include?(user)
    user
  end

  # Don't set default passwords in production mode
  def set_default_password?
    AuthConfig.use_database_auth? && !Rails.env.production?
  end

  # return an array of all users in the group
  # @return [Array(User)]
  def users
    raise "No users are defined" unless user_role.users.count.positive?
    user_role.users
  end

  private

    def create_user(uid, provider)
      @logger.debug "Creating new user #{uid}"
      user = ::User.create(uid: uid)
      user.password = "123456" if set_default_password?
      user.ppid = uid # temporary ppid, will get replaced when user signs in with shibboleth
      user.provider = provider
      user.save
      user
    end

    def add_user_to_group(uid, user)
      @logger.debug "Adding user #{uid} to #{@user_group}"
      user_role.users << user
      user_role.save
    end
end
