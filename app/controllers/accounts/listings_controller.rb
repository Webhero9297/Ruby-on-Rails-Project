# encoding: UTF-8
class Accounts::ListingsController < ApplicationController
  filter_access_to :all
  layout "dashboard"

  def index
    @account = Account.has_permission(current_user).find(params[:account_id])
    @listings = @account.listings.all

    @active_listing = ActiveListing.new
    profile_params = ValidProfile.get_validation_params(@account)
    @valid_profile = ValidProfile.new(profile_params)
    @valid_profile.valid?

    respond_to do |format|
      format.html
    end
  end

  def show
    @account = Account.has_permission(current_user).find(params[:account_id])
    @listing = @account.listings.find(params[:id]);

    respond_to do |format|
      format.html
    end
  end

  def statistics
    @account = Account.has_permission(current_user).find(params[:account_id])
    @listings = @account.listings.all
  end
end
