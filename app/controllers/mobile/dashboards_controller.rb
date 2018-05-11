# encoding: UTF-8
class Mobile::DashboardsController < ApplicationController

  #filter_access_to :all
  layout 'mobile'
  before_filter :set_as_mobile

  def start

    @screen_title = 'Home'

    if not user_signed_in?
      redirect_to(mobile_login_path)
      return
    end
    
    @favorites = current_user.account.get_favorites() 
    
    respond_to do |format|
      format.html
    end
  end


  def guest

    @screen_title = 'Intervac Home Exchange'
    
    respond_to do |format|
      format.html
    end
  end
end
