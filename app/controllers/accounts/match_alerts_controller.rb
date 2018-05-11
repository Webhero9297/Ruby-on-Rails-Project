class Accounts::MatchAlertsController < ApplicationController
  layout 'dashboard'

  def index
    @account = Account.find(params[:account_id])
    match_alert = @account.match_alert

    @destinations = match_alert.locations

    @house_filters = match_alert.house_filters
    @house_type_filters = match_alert.house_type_filters
    @exchange_type_filters = match_alert.exchange_type_filters
    @environment_filters = match_alert.environment_filters
    @surroundings = match_alert.surroundings

    @earliest_date = match_alert.earliest_date
    @latest_date = match_alert.latest_date
    @capacity = match_alert.capacity
    @adults = match_alert.adults
    @children = match_alert.children
    @reversed = match_alert.reversed
    @reversed_area = match_alert.reversed_area
    @hotlist = match_alert.hotlist
    @min_duration = match_alert.min_duration
    @pets = match_alert.pets
    @ee = match_alert.ee
    @languages_array = match_alert.spoken_languages
    @open_for_exchange = "match_alert" # it will not be displayed

    @environments      = Environment.all
    @exchange_types    = ExchangeType.selectable
    @house_types       = HouseType.selectable
    @property_details  = PropertyDetail.selectable
    @surrounding_types = Listing::SURROUNDING_TYPES
  end

  def add_location
    @account = Account.find(params[:account_id])
    @location = @account.match_alert.add_location(params[:location])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def remove_location
    @account = Account.has_permission(current_user).find(params[:account_id])
    @account.match_alert.remove_location(params[:location])
    @item_id = params[:location]
    respond_to do |format|
      format.html
      format.js
    end
  end

  def add_filters
    @account = Account.find(params[:account_id])
    match_alert = @account.match_alert
    match_alert.set_filters(params)
    match_alert.save

    respond_to do |format|
      format.html {redirect_to(action: 'index')}
      format.js
    end
  end

  def clear_filters
    @account = Account.find(params[:account_id])
    match_alert = @account.match_alert
    match_alert.clear_filters
    match_alert.save

    respond_to do |format|
      format.html { redirect_to(action: 'index') }
      format.js
    end
  end

  def activate
    @account = Account.find(params[:account_id])
    @account.match_alert.activate
    respond_to do |format|
      format.html {redirect_to(action: 'index')}
      format.js
    end
  end

  def disable
    @account = Account.find(params[:account_id])
    @account.match_alert.disable
    respond_to do |format|
      format.html {redirect_to(action: 'index')}
      format.js
    end
  end
end
