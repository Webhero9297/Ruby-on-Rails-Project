module CookieInformationBarsHelper
  ##
  #
  def show_cookie_bar?
    if cookies[:cookie_bar] == 'yes'
      return true
    end
    false
  end
end
