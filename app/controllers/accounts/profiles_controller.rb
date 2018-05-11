# encoding: UTF-8
class Accounts::ProfilesController < ApplicationController
  
  filter_access_to :all
  layout "dashboard"
  #before_filter :check_subscription
  
  def show
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    
    respond_to do |format|
      format.html
    end
  end
  
  
  def incomplete
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    @subscription = @account.current_subscription
    
    respond_to do |format|
      format.html
    end
  end

  def unconfirmed
    @account = Account.has_permission(current_user).find(params[:account_id])
    respond_to do |format|
      format.html
    end
  end


  def set_open_for_all_destinations
    
    account = Account.has_permission(current_user).find(params[:account_id])

    if params[:open_for_all_destinations].nil?
      flash[:success] = t('alert.no_longer_available_for_all_destinations')
      account.profile.set(:open_for_all_destinations, false)
      account.listings.each do |listing|
        listing.set(:account_open_for_all_destinations, false)
      end
    else
      flash[:success] = t('alert.available_for_all_destinations')
      account.profile.set(:open_for_all_destinations, true) 
      account.listings.each do |listing|
        listing.set(:account_open_for_all_destinations, true)
      end
    end
    
    respond_to do |format|
      format.js
    end
  end

  def update_number_of_adults
    account = Account.has_permission(current_user).find(params[:account_id])
    account.profile.update_number_of_adults(params[:profile][:number_of_adults])
    flash[:success] = t('alert.number_adults_updated')
    respond_to do |format|
      format.js
    end
  end
  
  
end
