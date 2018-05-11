# encoding: UTF-8
class Accounts::LifestylesController < ApplicationController
  
  filter_access_to :all
  layout "dashboard"

  def show

    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @account = @listing.account
    @profile = @account.profile
    @profile_images = @profile.get_images_by_category(['lifestyle']).order_by([[:order, :asc]])
    
    respond_to do |format|
      format.html
    end
  end
  
  def edit
    
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @account = @listing.account
    @profile = @account.profile
    
    respond_to do |format|
      format.js
    end
  end
  
  
  def update
    
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @account = @listing.account
    @profile = @account.profile

    respond_to do |format|
      if @profile.update_attributes(lifestyle_params)
        @listing.set_last_updated
        flash[:notice] = t('alert.lifestyle_presentation_updated')
        format.js
      else
        format.js { render action: "edit" }
      end
    end
  end
  
  
  def cancel
    
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @account = @listing.account
    @profile = @account.profile
    
    respond_to do |format|
      format.js
    end
  end
  
private
  
  def lifestyle_params
    params.require(:profile).permit(lifestyle_attributes: [:text, :visible])
  end

end
