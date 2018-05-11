require File.expand_path('../boot', __FILE__)
require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"
require "rails/test_unit/railtie"
require 'yajl/json_gem'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Intervac
  class Application < Rails::Application
    # Phusion Passenger has a limited PATH, so we have to include `/usr/bin`
    # in order to use imagemagick commands.
    ENV['PATH'] += File::PATH_SEPARATOR + '/usr/bin/'

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/lib/modules)
    config.autoload_paths += %W(#{config.root}/lib/i18n)
    config.autoload_paths += %W(#{config.root}/lib/devise)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :en_GB
    config.i18n.fallbacks = true

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # Specify wich action mailer delivery method to use
    config.action_mailer.delivery_method = :mailgun

    # Countries that has their own sites
    config.country_sites = ['au', 'be', 'ca', 'de', 'dk', 'es', 'fi', 'fr', 'gb', 'ie', 'is', 'it', 'ja', 'nl', 'no', 'nz', 'pl', 'pt', 'ru', 'se', 'uk', 'us']

    # All currencies availble via PayPal
    config.currencies = ['AUD', 'CAD', 'EUR', 'GBP', 'JPY', 'USD', 'NZD', 'CHF', 'HKD', 'SGD', 'SEK', 'DKK', 'PLN', 'NOK', 'HUF', 'CZK', 'ILS', 'MXN', 'BRL', 'MYR', 'PHP', 'TWD', 'THB', 'TRY']

    # PayPal supported locales and translated locales via Active Merchant
    config.paypal_locales = ['AU', 'AT', 'BE', 'BR', 'CA', 'CH', 'CN', 'DE', 'ES', 'GB', 'FR', 'IT', 'NL', 'PL', 'PT', 'RU', 'US', 'DK', 'IL', 'ID', 'JP', 'NO', 'BR', 'RU', 'SE', 'TH', 'TR', 'CN', 'HK', 'TW']

    # French sites used for checking what kind of payment and search options that are available for the user.
    config.french_sites = ['BL', 'FR', 'GP', 'MC', 'MF', 'MQ', 'NC', 'PF', 'PM', 'RE', 'TF', 'WF', 'YT', 'GF']
    config.french_payment_url = 'https://www.intervac.fr/cmd_international'

    # Sites that should use sage pay as payment gateway. Sage Pay payment url is configured in respective environment file.
    config.sage_pay_sites = ['UK', 'GB', 'AI', 'FK', 'TC', 'VG']

    # Add the fonts path
    config.assets.paths << "#{Rails.root}/vendor/assets/fonts"

    # Precompile additional assets
    config.assets.precompile += %w( .svg .eot .woff .ttf )

    # Custom routes for page not found and error pages through the errors controller
    config.exceptions_app = self.routes

    config.to_prepare do
      Devise::Mailer.layout "notification_mailer"
      Devise::Mailer.helper :application
    end

    config.gem 'rack-recaptcha', :lib => 'rack/recaptcha'
    config.middleware.use Rack::Recaptcha, :public_key => '6LcwfO4SAAAAAL4oGPzP448Fw2rjhoRkUPyBy7qe', :private_key => '6LcwfO4SAAAAAHHcY8oW1wroew6LVih6r3tbSiMP'

  end
end
