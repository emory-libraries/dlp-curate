# Set up admin users
require 'yaml'

# Set up application's initial state: load required roles and users
class AdminSetup
  attr_accessor :admins_config
  DEFAULT_ADMIN_CONFIG = "#{::Rails.root}/config/role_map.yml".freeze

  # Set up the parameters for
  # @param [String] admins_config a file containing the email addresses of the application's admin users
  def initialize(admins_config = DEFAULT_ADMIN_CONFIG, log_location = STDOUT)
    raise "File #{admins_config} does not exist" unless File.exist?(admins_config)
    @admins_config = YAML.safe_load(File.read(admins_config))
    @logger = Logger.new(log_location)
    @logger.level = Logger::DEBUG
    @logger.info "Initializing new admin setup with admins file #{admins_config}"
  end

  # Load the admins
  def setup
    load_admins
  end

  # Create the admin role, or find it if it exists already
  # @return [Role] the admin Role
  def admin_role
    Role.find_or_create_by(name: "admin")
  end

  # Load admins from a config file
  def load_admins
    admin_role.users = [] # Remove all the admin users every time you reload
    admin_role.save
    @admins_config.each_key do |provider|
      @admins_config[provider]["admin"].each do |a|
        make_admin(a, provider)
      end
    end
  end

  # Make an admin
  # @param [String] the uid of the admin
  # @return [User] the admin who was just created
  def make_admin(uid, provider = "development")
    @logger.debug "Making admin #{uid}"
    admin_user = ::User.find_or_create_by(uid: uid)
    admin_user.password = "123456" if set_default_password?
    admin_user.ppid = uid # temporary ppid, will get replaced when user signs in with shibboleth
    admin_user.provider = provider
    admin_user.save
    admin_role.users << admin_user
    admin_role.save
    admin_user
  end

  # Don't set default passwords in production mode
  def set_default_password?
    AuthConfig.use_database_auth? && !Rails.env.production?
  end

  # return an array of all current admins
  # @return [Array(User)]
  def admins
    raise "No admins are defined" unless admin_role.users.count > 0
    admin_role.users
  end
end
