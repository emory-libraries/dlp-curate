# frozen_string_literal: true
require 'webdrivers' if ENV['CI']

client = Selenium::WebDriver::Remote::Http::Default.new
options = Selenium::WebDriver::Chrome::Options.new

client.read_timeout = ENV.fetch('CAPYBARA_WAIT_TIME', 10).to_i
client.open_timeout = ENV.fetch('CAPYBARA_WAIT_TIME', 10).to_i

options.add_argument('--headless')
options.add_argument("--disable-gpu")
options.add_argument('--no-sandbox')
options.add_argument('--disable-dev-shm-usage')
options.add_argument('--window-size=1400,1400')
options.add_argument("--dns-prefetch-disable")

if ENV['CI']
  Webdrivers.cache_time = 3

  # Setup chrome headless driver
  Capybara.server = :puma, { Silent: true }

  Capybara.register_driver :selenium_chrome_headless_sandboxless do |app|
    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options, http_client: client)
  end
else
  Capybara.register_driver :selenium_chrome_headless_sandboxless do |app|
    driver = Capybara::Selenium::Driver.new(app,
                                        browser: :remote,
                                        http_client: client,
                                        capabilities: options,
                                        url: ENV['HUB_URL'])

    # Fix for capybara vs remote files. Selenium handles this for us
    driver.browser.file_detector = lambda do |args|
      str = args.first.to_s
      str if File.exist?(str)
    end

    driver
  end

  Capybara.server_host = '0.0.0.0'
  Capybara.server_port = 3010

  ip = IPSocket.getaddress(Socket.gethostname)
  Capybara.app_host = "http://#{ip}:#{Capybara.server_port}"
end


Capybara.default_driver = :rack_test # This is a faster driver
Capybara.javascript_driver = :selenium_chrome_headless_sandboxless # This is slower
Capybara.default_max_wait_time = ENV.fetch('CAPYBARA_WAIT_TIME', 10).to_i # We may have a slow application, let's give it some time.

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :selenium_chrome_headless_sandboxless
  end
end
