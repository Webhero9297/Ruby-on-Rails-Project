# encoding: utf-8
class Listing::ExchangeDatesController < ApplicationController
  filter_access_to :all
  layout "dashboard"
  before_filter :check_subscription
  
  def index
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    
    respond_to do |format|
      format.html
    end
  end
  
  
  def show
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
  end
  
  
  def new
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    listing_params = ActiveListing.get_validation_params(@listing)
    @active_listing = ActiveListing.new(listing_params)
    @exchange_dates = ExchangeDate.new
    
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  
  def edit
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    listing_params = ActiveListing.get_validation_params(@listing)
    @active_listing = ActiveListing.new(listing_params)
    @exchange_dates = @listing.exchange_dates.find(params[:id])
    
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  
  def cancel
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    listing_params = ActiveListing.get_validation_params(@listing)
    @active_listing = ActiveListing.new(listing_params)
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  
  def create
    
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    listing_params = ActiveListing.get_validation_params(@listing)
    @active_listing = ActiveListing.new(listing_params)
    @exchange_dates = @listing.exchange_dates.new(exchange_date_params)
    @listing.set_last_updated
    
    respond_to do |format|
      if @exchange_dates.save
        format.html { redirect_to( {action: 'index'}, {notice: t('alert.exchange_dates_created')}) }
        format.js
      else
        format.html { render action: "new" }
        format.js { render action: "edit" }
      end
    end
  end
  
  
  def update
    # TODO check that the user doesn't try change the exchange date after adding a listing to the hot list
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    listing_params = ActiveListing.get_validation_params(@listing)
    @active_listing = ActiveListing.new(listing_params)
    @exchange_dates = @listing.exchange_dates.find(params[:id]).update_attributes!(exchange_date_params)
    @listing.set_last_updated

    #Removed ftom Hotlist if exchange date change is not hotlist valid
    if @listing.is_in_hot_list and not @listing.is_available_for_hot_list
      @listing.remove_from_hot_list
    end
    
    respond_to do |format|
      format.html { redirect_to({action: 'index'}, {notice: t('alert.exchange_dates_updated')}) }
      format.js
    end
  end
  
  
  def destroy
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    listing_params = ActiveListing.get_validation_params(@listing)
    @active_listing = ActiveListing.new(listing_params)
    @listing.exchange_dates.delete_all(conditions: { id: params[:id] })
    @date_id = params[:id]

    #Removed ftom Hotlist if exchange date change is not hotlist valid
    if @listing.is_in_hot_list and not @listing.is_available_for_hot_list
      @listing.remove_from_hot_list
    end

    respond_to do |format|
      format.html { redirect_to({action: 'index'}, {notice: t('alert.exchange_dates_deleted')}) }
      format.js
    end
  end


private
  
  def exchange_date_params
    params.require(:exchange_date).permit(:earliest_date, :latest_date, :length_of_stay, :periodicity, :note)
  end
  
end
