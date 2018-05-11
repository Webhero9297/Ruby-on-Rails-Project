# encoding: utf-8
class Listing::PropertySettingsController < ApplicationController
  filter_access_to :all
  layout "dashboard"
  before_filter :check_subscription
  
  def edit
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @property_details = PropertyDetail.selectable
    @exchange_types = ExchangeType.selectable
    @property_details = PropertyDetail.selectable
    
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  
  def update
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @listing.update_property_details(params[:listing][:property_details])
    
    @property_details = PropertyDetail.selectable
    @exchange_types = ExchangeType.selectable
    @property_details = PropertyDetail.selectable
    
    respond_to do |format|
      if @listing.update_property_details(params[:listing][:property_details])
        @listing.set_last_updated
        format.html { redirect_to edit_listing_property_setting_url(@listing), notice: t('alert.listing_details_updated') }
        format.js
      else
        format.html { render action: "edit" }
        format.js { render action: "edit" }
      end
    end
  end
  
  
  def cancel
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @property_details = PropertyDetail.selectable
    @exchange_types = ExchangeType.selectable
    @property_details = PropertyDetail.selectable
    
    respond_to do |format|
      format.html { redirect_to overview_listing_url(@listing), notice: t('alert.editing_cancelled') }
      format.js {render(template: '/listing/property_settings/update.js.erb')}
    end
  end

end