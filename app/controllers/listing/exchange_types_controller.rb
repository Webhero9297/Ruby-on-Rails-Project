# encoding: UTF-8
class Listing::ExchangeTypesController < ApplicationController
  
  filter_access_to :all
  layout "dashboard"
  before_filter :check_subscription
  
  def edit
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @exchange_types = ExchangeType.selectable
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  
  def update
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @exchange_types = ExchangeType.selectable
    @listing.update_exchange_types(params[:listing][:exchange_types])
    
    respond_to do |format|
      if @listing
        @listing.set_last_updated
        format.html { redirect_to edit_listing_exchange_type_url(@listing), notice: t('alert.exchange_types_updated') }
        format.js
      else
        format.html { render action: "edit" }
        format.js { render action: "edit" }
      end
    end
  end
  
  
  def cancel
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @exchange_types = ExchangeType.selectable
    
    respond_to do |format|
      format.html { redirect_to overview_listing_url(@listing), notice: t('alert.editing_cancelled') }
      format.js {render(template: '/listing/exchange_types/update.js.erb')}
    end
  end
  
  def edit_duration
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    respond_to do |format|
      format.js
    end
  end
  
  
  def update_duration
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @listing.update_attribute(:max_duration, params[:listing][:max_duration])
    respond_to do |format|
        format.js 
    end
  end
  
  
  def cancel_duration
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    respond_to do |format|
      format.js
    end
  end


end
