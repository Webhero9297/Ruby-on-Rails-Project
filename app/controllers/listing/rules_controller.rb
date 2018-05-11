# encoding: UTF-8
class Listing::RulesController < ApplicationController
  filter_access_to :all
  layout "dashboard"
  before_filter :check_subscription
  
  def edit
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  
  def update
    @listing = Listing.has_permission(current_user).find(params[:listing_id])

    respond_to do |format|
      if @listing.update_children_pets_settings(params[:listing])
        @listing.set_last_updated
        flash[:notice] = t('alert.pets_and_children_updated')
        format.js
      else
        format.js {render(action: 'edit')}
      end
    end
  end
  
  
  def cancel
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    
    respond_to do |format|
      format.html { redirect_to overview_listing_url(@listing), notice: t('alert.cancelled_editing_description') }
      format.js {render(template: '/listing/rules/update.js.erb')}
    end
  end
  
end