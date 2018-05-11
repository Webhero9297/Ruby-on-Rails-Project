# encoding: UTF-8
class Accounts::SpokenLanguagesController < ApplicationController
  
  filter_access_to :all
  layout "dashboard"
  #before_filter :check_subscription
  
  def edit
    @languages = Language.all
    @account = Account.has_permission(current_user).find(params[:account_id])
    
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  
  def update
    @languages = Language.all
    @account = Account.has_permission(current_user).find(params[:account_id])
    
    respond_to do |format|
      if @account.profile.set_spoken_languages(params[:spoken_languages])
        format.html { redirect_to(edit_account_spoken_languages_url(@account), notice: t('alert.spoken_languages_updated')) }
        format.js
      else
        format.html { render action: "edit" }
        format.js { render action: "edit" }
      end
    end
  end
  
  
  def cancel
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    
    respond_to do |format|
      format.html {redirect_to(overview_account_profiles_url)}
      format.js {render(template: '/accounts/spoken_languages/update.js.erb')}
    end
  end
  
end
