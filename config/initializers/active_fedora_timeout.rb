# frozen_string_literal: true
# [Overwrite - ActiveFedora ~> 11.5.4]
# We are adding request options (timeouts) when creating a new Faraday connection.
# This is added in ActiveFedora 12+ and this file can be removed once we upgrade
# AF. Refer: https://github.com/samvera/active_fedora/pull/1271
# We are overwriting the `authorized_connection` method from Fedora class in AF.
class ActiveFedora::Fedora
  def request_options
    @config[:request]
  end

  def authorized_connection
    options = {}
    options[:ssl] = ssl_options if ssl_options
    options[:request] = request_options if request_options
    Faraday.new(host, options) do |conn|
      conn.response :encoding # use Faraday::Encoding middleware
      conn.adapter Faraday.default_adapter # net/http
      conn.basic_auth(user, password)
    end
  end
end
