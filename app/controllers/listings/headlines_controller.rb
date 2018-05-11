# encoding: UTF-8
class Listings::HeadlinesController < ApplicationController
  layout 'dashboard'

  def edit

    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    
    respond_to do |format|
      format.js
    end
  end


  def update
    
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @listing.set(:headline, params[:listing][:headline])
    @listing.set_last_updated
    flash[:notice] = t('alert.headline_updated')
    respond_to do |format|
      format.js
    end
  end


  def cancel
    
    @listing = Listing.has_permission(current_user).find(params[:listing_id])

    respond_to do |format|
      format.js
    end
  end
end
