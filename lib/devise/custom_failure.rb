# encoding: UTF-8

##
# Overrides the devise FailureApp to make it possible to redirect to different paths depending on where the user login from.
class CustomFailure < Devise::FailureApp
  
  def redirect_url
    if session[:mobile_login_url] != mobile_start_path
      flash[:alert] = i18n_message(:invalid)
      user_session_path
    else
      flash[:alert] = i18n_message(:invalid)
      mobile_login_path
    end
  end


  def respond
    if http_auth?
      http_auth
    else
      redirect
    end
  end

end