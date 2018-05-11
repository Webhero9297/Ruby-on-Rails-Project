# encoding: UTF-8
class Users::PasswordsController < Devise::PasswordsController
  include SslHelpers
  force_ssl if: :ssl_configured?

  def resource_params
    params.require(:user).permit(:email, :password, :password_confirmation, :reset_password_token)
  end
  private :resource_params

end
