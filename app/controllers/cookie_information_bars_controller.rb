# encoding: utf-8
class CookieInformationBarsController < ApplicationController

  def accept_cookies

    cookies.delete(:cookie_bar, domain: :all)
    cookies.permanent[:cookie_bar] = {:value => 'no', :domain => :all}

    respond_to do |format|
      format.js
      format.html {redirect_to(root_path)}
    end
  end
end
