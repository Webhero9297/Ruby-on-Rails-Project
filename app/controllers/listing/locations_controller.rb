# encoding: utf-8
class Listing::LocationsController < ApplicationController
  filter_access_to :all
  layout "dashboard"
  before_filter :check_subscription

  def edit
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @environments = Environment.all.to_a
    respond_to do |format|
      format.js
    end
  end

  def update
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    listing = @listing.update_location(params)

    respond_to do |format|
      if listing
        format.html { redirect_to edit_listing_location_url(@listing), notice: t('alert.locations_updated') }
        format.js
      else
        format.html { render action: "edit" }
        format.js { render action: "edit" }
      end
    end
  end

  def update_visibility
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @listing.set_map_visiblity(params[:status])
    flash.now[:success] = t('alert.map_visibility_updated')
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
