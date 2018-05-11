# encoding: utf-8
class Listing::FacilitiesController < ApplicationController
  
  filter_access_to :all
  layout "dashboard"
  before_filter :check_subscription
  
  def edit
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @property_details = PropertyDetail.selectable
  end
  
  
  def update
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @listing.update_property_details(params[:listing][:property_details])
    
    respond_to do |format|
      if @listing
        format.html { redirect_to editlisting_facility_url(@listing), notice: t('alert.listing_facilities_updated') }
      else
        format.html { render action: "edit" }
      end
    end
  end
  
end
