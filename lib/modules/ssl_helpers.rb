module SslHelpers
  ##
  # Helper to check if ssl should be used or not.
  # Made as a module to be able to use in devise overridden controllers
  # without declaring it over and over again.
  def ssl_configured?
    not (Rails.env.development? || Rails.env.staging?)
  end
end
