# encoding: utf-8
class ProfileImagesController < ApplicationController
  filter_access_to :all
  layout "dashboard"
  
  def index
    @profile = current_user.account.profile
    @profile_image = ProfileImage.new
    
    @family_images = @profile.get_images_by_category('family')
    @lifestyle_images = @profile.get_images_by_category('lifestyle')
    
    respond_to do |format|
      format.html
    end
  end
  
  
  def edit
    @profile = current_user.account.profile
    @profile_image = @profile.profile_images.find(params[:id])
    
    respond_to do |format|
      format.html
    end
  end
  
  
  def create
    @profile = current_user.account.profile
    @family_images = @profile.get_images_by_category('family')
    @lifestyle_images = @profile.get_images_by_category('lifestyle')
    
    @profile_image = @profile.profile_images.new(:category => params[:category])
    @profile_image.image = params[:file]
    
    respond_to do |format|
      if @profile_image.valid?
        @profile_image.save
        format.html { redirect_to(account_profile_profile_images_url, {notice: t('alert.image_successfully_uploaded')}) }
        format.js { render( partial: 'profile_image', object: @profile_image, as: 'image', :status => 200 )}
      else
        format.html { render(action: 'index') }
        format.js { render( :json => {:error => 'validation failed', :image => @profile_image.errors.full_messages}, :status => 202 )}
      end
    end
  end
  
  
  def update
    @profile = current_user.account.profile
    @profile_image = @profile.profile_images.find(params[:id]).update_attributes!(params[:profile_image])
    
    respond_to do |format|
      format.html { redirect_to(account_profile_profile_images_url, {notice: t('alert.image_successfully_updated')}) }
    end
  end
  
  
  def destroy
    @profile = current_user.account.profile
    @profile.profile_images.destroy_all(conditions: { id: params[:id] })
    
    respond_to do |format|
      format.html { redirect_to(account_profile_profile_images_url, {notice: t('alert.image_successfully_deleted')}) }
      format.js
    end
  end
  
end
