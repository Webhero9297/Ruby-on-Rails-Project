# encoding: UTF-8
class Accounts::WishListsController < ApplicationController
  
  filter_access_to :all
  layout "dashboard"
  #before_filter :check_subscription
  
  def index
    @account = Account.has_permission(current_user).find(params[:account_id])
    
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  
  def create
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    @destination = @profile.add_wish_list_destination(params[:destination])
    # Set wish list on listings for searching
    @profile.set_wishlist_on_listings()

    respond_to do |format|
      if @destination
        format.html { redirect_to(account_wish_lists_url(@account), notice: t('alert.wish_list_updated')) }
        format.js
      else
        format.html { render action: "edit" }
        format.js { render json: @destination.errors, status: :unprocessable_entity }
      end
    end
    
  end
  
  
  def destroy
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    @profile.wish_list_destinations.destroy_all(conditions: { id: params[:id] })
    
    # Set wish list on listings for searching
    @profile.set_wishlist_on_listings()

    respond_to do |format|
      format.html { redirect_to(account_wish_lists_url(@account), {notice: t('alert.wish_list_destination_deleted')}) }
      format.js
    end
  end
  
  
  def cancel
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    
    respond_to do |format|
      format.js
    end
  end
  
end
