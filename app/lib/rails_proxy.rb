class RailsProxy < Rack::Proxy
  def rewrite_env(env)
    # env['HTTP_HOST'] = 'example.com'
    # env['SERVER_PORT'] = 80

    # Remove forwarding parameters
    env['SCRIPT_NAME'] = nil
    env['HTTP_X_FORWARDED_PORT'] = nil
    env['HTTP_X_FORWARDED_PROTO'] = nil

    new_path = "/cantaloupe/iiif" + env['PATH_INFO']
    env['PATH_INFO'] = new_path
    # Return the 'env'
    env
  end
end
