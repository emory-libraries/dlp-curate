class AuthConfig
    # In production, we use Shibboleth for user authentication,
    # but in development mode, you may want to use local database
    # authentication instead.
    def self.use_database_auth?
      !Rails.env.production? && ENV['DATABASE_AUTH'] == 'true'
    end
end
