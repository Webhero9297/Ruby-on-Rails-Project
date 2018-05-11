# encoding: UTF-8
class SearchesController < ApplicationController
  PER_PAGE = [12, 24, 48]
  MAX_PAGE = 140

  layout 'searches'
  before_filter :common_variables, only: [:index, :search, :map, :map_search]
  before_filter :filter_params_and_set_env_vars, only: [:search, :map_search, :mapview_coords, :map, :index]

  def index
    @order_by_hash = {'updated_at' => t('filters.sorting.most_recent'), 'country' => t('filters.sorting.country'), 'listing_number' => t('filters.sorting.listing_number')}
    @order_by = 'updated_at'

    @listings = Listing.active_account.only_international(current_user).order_by([@order_by, :desc])

    @count = @listings.count
    @listings = @listings.page(@page).per(@per_page.to_i)

    if user_signed_in?
      user_account = current_user.account
      @favorites = []
      user_account.favorites.each do |favorite|
        @favorites.push(favorite.listing_id)
      end

      @saved_searches = user_account.searches
    end
  end

  def search
    @listings = ListingSearch.new.search(params)

    # French limits
    @listings = @listings.only_international(current_user)

    ############# SETTING PARAMS ##################
    begin
      @count = @listings.count
    rescue Mongo::OperationFailure
      # Mongo cant deal with empty conditions. This is an ugly fix for
      # the problem. We still have to understand this is happening.
      # Refer to #2711 for more info
      @count = 0
    end
    @listings = @listings.page(@page).per(@per_page.to_i)

    @order_by_hash = {'updated_at' => t('filters.sorting.most_recent'), 'country' => t('filters.sorting.country'), 'listing_number' => t('filters.sorting.listing_number')}

    if user_signed_in?
      user_account = current_user.account
      @favorites = []
      user_account.favorites.each do |favorite|
        @favorites.push(favorite.listing_id)
      end

      @saved_searches = user_account.searches
    end

    # Clean out unecessary info in params.
    # This is used to retain filters between map and destination search
    params.delete('action')
    params.delete('controller')

    respond_to  do |format|
      format.html { render :template => 'searches/index.html.erb' }
    end
  end

  def map
    if user_signed_in?
      @saved_searches = current_user.account.searches
    end

    @query_string = "?"
    if current_user
      # Handles the french limits
      @query_string += "current_user_country=#{current_user.account.country_short}"
    end

    # Clean out unecessary info in params.
    # This is used to retain filters between map and destination search
    params.delete('action')
    params.delete('controller')

    respond_to  do |format|
      format.html
    end
  end

  def map_search
    @query_string = "?"
    if current_user
      @query_string += "current_user_country=#{current_user.account.country_short}"
    end

    denied_params = ["destination_form"]
    @query_string += '&' + CGI::unescape(
      params.reject{|k,_| denied_params.include?(k)}.to_query
    )

    if user_signed_in?
      @saved_searches = current_user.account.searches
    end

    # Clean out unecessary info in params.
    # This is used to retain filters between map and destination search
    params.delete('action')
    params.delete('controller')

    respond_to  do |format|
      format.html { render :template => 'searches/map.html.erb' }
    end
  end

  def listing_info
    listing_number = params[:listing_number]
    listing = Listing.where(:listing_number => listing_number).first
    respond_to do |format|
      if listing
        main_photo = listing.get_main_photo
        format.js { render( :json => {:html => render_to_string(partial: 'info_window', locals: {listing: listing, main_photo: main_photo})}, :status => 200)}
      else
        format.js { render :json => nil, :status => :ok }
      end
    end
  end

  def mapview_coords
    listings = ListingSearch.new(:mapview).search(params)

    # French limits
    if params[:current_user_country]
      listings = listings.only_international(current_user)
    end

    coords = listings.map do |listing|
      {coord: [listing.lat, listing.lng], number: listing.listing_number}
    end

    respond_to do |format|
      format.js { render(:json => coords) }
    end
  end

  def go_to_listing
    @listing_number = params[:listing_number]
    if not @listing_number.blank?
      @listing_number.upcase!
      @listing = Listing.where(listing_number: @listing_number).active_account.only_international(current_user).first
    end

    respond_to do |format|
      if @listing
        format.html { redirect_to(listing_path(@listing)) }
      else
        flash[:notice] = t('searches.member_not_found', {:MEMBER_ID => @listing_number})
        format.html { redirect_to(searches_index_path) }
      end
    end
  end

  def do_saved_search
    search = current_user.account.get_search(params[:id])
    redirect_to url_for(:action => 'search', :params => search.params)
  end

  def save_search
    user_account = current_user.account
    respond_to do |format|
      if user_account.add_search(params)
        @saved_searches = user_account.get_saved_searches
        format.js
      end
    end
  end

  def delete_saved_search
    user_account = current_user.account
    user_account.delete_search(params[:id])
    @saved_searches = user_account.get_saved_searches
    respond_to do |format|
      format.js
    end
  end

  private

  def filter_params_and_set_env_vars
    @adults        = params[:adults]
    @capacity      = params[:capacity]
    @children      = params[:children]
    @country_short = params[:country_short]
    @hotlist       = params[:hotlist]
    @lat           = params[:lat]
    @lng           = params[:lng]
    @min_duration  = params[:min_duration]
    @ne_lat        = params[:ne_lat]
    @ne_lng        = params[:ne_lng]
    @pets          = params[:pets]
    @reversed      = params[:reversed]
    @reversed_data = params[:reversed_data]
    @reversed_area = params[:reversed_area]
    @sw_lat        = params[:sw_lat]
    @sw_lng        = params[:sw_lng]
    @zoom          = params[:zoom]

    @ee = params[:ee].present?
    @languages_array       = params["spoken_languages"].blank? ? []  : params["spoken_languages"]
    @destination           = params[:destination_form].blank?  ? nil : params[:destination_form]

    begin
      @earliest_date         = params[:earliest_date].blank?     ? nil : DateTime.parse(params[:earliest_date]).to_time.utc
      @latest_date           = params[:latest_date].blank?       ? nil : DateTime.parse(params[:latest_date]).to_time.utc
    rescue ArgumentError
      # this will catch the case of invalid date in case the user
      # doesn't use our date picker or insert any invalid characters
      # in the date field

      flash[:notice] = t('searches.invalid_date_format')
    end

    @house_filters         = params[:house_filters]         || []
    @house_type_filters    = params[:house_type_filters]    || []
    @exchange_type_filters = params[:exchange_type_filters] || []
    @environment_filters   = params[:environment_filters]   || []
    @surroundings          = params[:surroundings]          || []
    @order_by              = params[:order_by]              || 'updated_at'

    @open_for_exchange = params[:open_for_exchange].try(:to_bool)

    @page = params[:page].to_i < MAX_PAGE ? params[:page] : MAX_PAGE

    @per_page = params[:per_page] || PER_PAGE.first
    @per_page = PER_PAGE.last.to_s if @per_page.to_i > PER_PAGE.last
  end

  def common_variables
    @environments      = Environment.all
    @exchange_types    = ExchangeType.selectable
    @house_types       = HouseType.selectable
    @property_details  = PropertyDetail.selectable
    @surrounding_types = Listing::SURROUNDING_TYPES
  end
end
