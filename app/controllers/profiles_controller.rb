# encoding: utf-8
class ProfilesController < ApplicationController
  filter_access_to :all
  layout "dashboard"
  
  def show
    @profile = current_user.account.profile
    @uncategorized_images = @profile.get_images_by_category('uncategorized')
    @family_images = @profile.get_images_by_category('family')
    @lifestyle_images = @profile.get_images_by_category('lifestyle')
  end
  
  
  def edit
    @account = current_user.account
    @profile = @account.profile
  end
  
  
  def update
    @profile = current_user.account.profile

    respond_to do |format|
      if @profile.update_attributes(params[:profile])
        format.html { redirect_to(account_profile_url, notice: t('alert.family_profile_updated')) }
        format.js
      else
        format.html { render action: "edit" }
        format.js
      end
    end
    
  end
  
end
