# encoding: UTF-8
class Mobile::SessionsController < Devise::SessionsController

  filter_access_to :all
  layout 'mobile'
  before_filter :set_as_mobile

  def new
    @screen_title = "Login"
    session[:mobile_login_url] = mobile_start_path
    respond_to do |format|
      format.html {render :template => '/mobile/sessions/new'}
    end
  end
  

  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message :notice, :signed_out if signed_out && is_navigational_format?

    respond_to do |format|
      format.html { redirect_to(:action => 'new')}
    end
    
  end

end
