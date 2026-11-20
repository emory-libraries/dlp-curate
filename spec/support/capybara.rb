# frozen_string_literal: true

module Chrome158CdpOriginFix
  def execute_cdp(cmd, **params)
    if cmd == 'Storage.clearDataForOrigin' && params[:origin] == '*'
      url = current_url
      return unless url&.start_with?('http')

      uri = URI.parse(url)
      params = params.merge(origin: "#{uri.scheme}://#{uri.host}:#{uri.port}")
    end
    super(cmd, **params)
  end
end

# Setup chrome headless driver
Capybara.server = :puma, { Silent: true }

Capybara.register_driver :chrome_headless do |app|
  client = Selenium::WebDriver::Remote::Http::Default.new
  client.read_timeout = 120

  options = ::Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1400,1400')

  driver = Capybara::Selenium::Driver.new(app, browser: :chrome, options:, http_client: client)
  driver.browser.singleton_class.prepend(Chrome158CdpOriginFix)
  driver
end

Capybara.javascript_driver = :chrome_headless

# Setup rspec
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :chrome_headless
  end
end
