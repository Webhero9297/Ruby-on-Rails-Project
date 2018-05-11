class Users::SessionsController < Devise::SessionsController
  include SslHelpers
  force_ssl if: :ssl_configured?
end
