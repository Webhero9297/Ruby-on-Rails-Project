# encoding: utf-8
class Listing::SurroundingsController < ApplicationController
  filter_access_to :all
  layout "dashboard"
  before_filter :check_subscription

  def show
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @main_photo = @listing.get_main_photo
    @listing_images = @listing.get_images_by_category(['surroundings'])
    @listing_image = ListingImage.new
    respond_to do |format|
      format.html
    end
  end

  
  def edit
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
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
  
  
  def update
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    
    surroundings = []
    if params[:pins]
      params[:pins].each do |item|
        item[1]['id']=item[0]
        item[1]['distance']=item[1]['distance'].to_f
        surroundings.push(item[1])
      end
    end
    
    
    @listing.surroundings = surroundings
    respond_to do |format|
      if @listing.valid?
        @listing.save
        @listing.set_last_updated
        format.html { redirect_to edit_listing_surrounding_url(@listing), notice: t('alert.listing_details_updated') }
        format.js
      else
        format.html { render action: "edit" }
        format.js { render action: "edit" }
      end
    end
    
  end

  def edit_airport
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    
    respond_to do |format|
      format.js
    end
  end

  def edit_description
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    
    respond_to do |format|
      format.js
    end
  end

  def update_airport
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @listing.update_attributes(:distance => params[:listing][:distance],:airport => params[:listing][:airport])
    @listing.set_last_updated
    
    respond_to do |format|
      format.js
    end
  end
  def update_description

    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @listing.update_attribute(:surrounding, params[:listing][:surrounding])
    @listing.set_last_updated
    
    respond_to do |format|
      format.js
    end
  end


  def cancel_description
    
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    respond_to do |format|
      format.js
    end
  end
  def cancel_airport
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    respond_to do |format|
      format.js
    end
  end
  
end
