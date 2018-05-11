# encoding: UTF-8
class ListingStatisticsController < ApplicationController
  
  filter_access_to :all
  layout 'dashboard'
  
  def index
    @stats = ''
    @account = Account.has_permission(current_user).find(current_user.account_id)
    @listings = @account.listings.all
    respond_to do |format|
      format.html {render :template => 'listing/statistics/index.html.erb'}
      format.json {render :json => @stats}
    end
  end
  
  
  def show
    @stats = ''
    respond_to do |format|
      format.json {render :json => @stats}
    end
  end
  
  
  def stats
    listing = Listing.find(params[:listing_id])
    @stats = {}
    @stats[:views] = listing.count_per_date(21)
    @stats[:countries] = listing.top_countries
    respond_to do |format|
      format.json {render :json => @stats}
    end
  end
  
end
