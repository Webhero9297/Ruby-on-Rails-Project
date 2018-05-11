# encoding: UTF-8
class Member::HotListsController < ApplicationController
  filter_access_to :all
  layout 'dashboard'
  before_filter :check_subscription
  
  
  def add
    
    listing = Listing.has_permission(current_user).find(params[:listing_id])
    marked = listing.mark_for_hot_list
    @listing = listing
    @listing.reload
    respond_to do |format|
      if marked
        flash[:notice] = t('alert.listing_added_hotlist')
        format.html { redirect_to overview_listing_url(listing) }
        format.js { render( template: 'listings/set_availability_with_hotlist' ) }
      else
        flash[:alert] = t('alert.listing_not_added_hotlist')
        format.html { redirect_to overview_listing_url(listing) }
        format.js { render( template: 'listings/set_availability_with_hotlist' ) }
      end
    end
  end
  
  
  def remove
    
    listing = Listing.has_permission(current_user).find(params[:listing_id])
    listing.remove_from_hot_list
    @listing = listing
    flash[:notice] = t('alert.listing_removed_hotlist')
    respond_to do |format|
      format.html { redirect_to overview_listing_url(listing) }
      format.js { render( template: 'listings/set_availability_with_hotlist' ) }
    end
  end
  
end
