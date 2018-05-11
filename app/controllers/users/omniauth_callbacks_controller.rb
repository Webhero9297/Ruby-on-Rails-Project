# encoding: UTF-8
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  
  def facebook
    
    # If there is a Facebook graph id connected to the user, sign in the user
    @user = User.find_for_facebook_oauth(request.env["omniauth.auth"], current_user)
    if not @user.nil?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Facebook"
      sign_in_and_redirect @user, :event => :authentication
      return
    end
    
    # If the user share the same email as the used Facebook email, link the accounts and sign in the user.
    @user = User.find_by_email(request.env["omniauth.auth"].info.email)
    if not @user.nil?
      auth = request.env["omniauth.auth"]
      @user.link_user_to_facebook(auth.uid)
      sign_in_and_redirect @user, :event => :authentication
      return
    end
    
    # Redirect the user to an information page with instructions on how to link the intervac account with facebook
    redirect_to(facebook_login_information_url)
    
  end
  
end
