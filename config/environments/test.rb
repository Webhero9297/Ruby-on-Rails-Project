Intervac::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

  config.assets.prefix = "/dev-assets"

  config.action_mailer.default_url_options = { :host => 'localhost:3000' }

  config.action_mailer.asset_host = 'http://localhost:3000'

  # Mailgun settings
  config.action_mailer.mailgun_settings = {
    :api_key  => 'key-6g7mg0i1fjr4xusn9x6vi6xr5fozqlg2',
    :api_host => 'api.mailgun.net/v2/intervac.mailgun.org/messages'
  }

  config.verify_message_key = 'key-6g7mg0i1fjr4xusn9x6vi6xr5fozqlg2'
  config.conversation_email = 'conversation@intervac.mailgun.org'

  config.action_mailer.delivery_method = :test
  config.main_domain = 'localhost:3000'
  config.external_domain = 'localhost:3000'

  config.paypal_options = {
    :login => "seller_1344936686_biz_api1.modondo.com",
    :password => "1344936704",
    :signature => "AFcWxV21C7fd0v3bYYYRCpSSRl31Apa0X.xvX.DnrXlWz9tuqwNObGik",
    :default_currency => "EUR",
    :merchant => "Intervac Test Paypal Express"
  }

  # Sage Pay Test Account - At the moment connected to Brian Hayes. If further agents should use SagePay, a re-factor has to be made to handle the payment settings
  config.sage_pay_vendor_name = 'bdw3b313473'
  config.sage_pay_crypt_secret = 'VxMc59DAE6qvnMa3'

  # Urban Airship auth keys development
  config.urban_airship_app_key = '1wj906wvSLGKDEP4eOShIg'
  config.urban_airship_master_secret = 'OwHMpvWVTAy35QaCHcH-mQ'

  config.after_initialize do
    ActiveMerchant::Billing::Base.mode = :test

    paypal_options = {
      :login => "intervac_api1.modondo.com",
      :password => "FMYUXATXXDY74M89",
      :signature => "AyoKhq.q-biu8gTard7isiQ5upnMATGQ-sEzx.KlSTTRYh6m951szXhH",
      :default_currency => 'EUR',
      :merchant => 'Intervac International'
    }
    ::EXPRESS_GATEWAY = ActiveMerchant::Billing::PaypalExpressGateway.new(paypal_options)
  end

  # Sage Pay test post url
  config.sage_pay_payment_url = 'https://test.sagepay.com/gateway/service/vspform-register.vsp'
end
