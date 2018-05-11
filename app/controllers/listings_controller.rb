# encoding: UTF-8
class ListingsController < Base::BaseListingController
  filter_access_to :all

  def index
    @house_filters = []
    @house_type_filters = []
    @exchange_type_filters = []
    @environment_filters = []
    @surroundings = []

    @exchange_types = ExchangeType.selectable
    @environments = Environment.all
    @property_details = PropertyDetail.selectable
    @house_types = HouseType.selectable

    @surrounding_types = Listing::SURROUNDING_TYPES

    @order_by_hash = {'updated_at' => t('filters.sorting.most_recent'), 'country' => t('filters.sorting.country'), 'listing_number' => t('filters.sorting.listing_number')}
    @order_by = 'updated_at'

    @per_page_hash = {'12' => '12', '24' => '24', '48' => '48'}
    @per_page = '12'

    @listings = Listing.active_account.searchable.only_international(current_user).order_by([@order_by, :desc])

    @count = @listings.count
    @listings = @listings.page(params[:page]).per(@per_page.to_i)

    if user_signed_in?
      user_account = current_user.account
      @favorites = []
      user_account.favorites.each do |favorite|
        @favorites.push(favorite.listing_id)
      end
      @saved_searches = user_account.get_saved_searches
    end

    respond_to do |format|
      format.html {render(template: '/searches/index.html.erb', layout: 'searches')}
    end
  end

  def show
    # Test with both ID and Listing number
    @listing = Listing
    if current_user
      @listing = @listing.only_international(current_user)
    end
    @listing = @listing.any_of({ _id: params[:id] }, { listing_number: params[:id].upcase }).first

    if @listing.blank?
      vip_countries = Country.get_shorts_as_array('vip')
      vip_countries = vip_countries.sample(60)
      @vip_listings = Listing.searchable.has_main_photo.where(:country_code.in => vip_countries).order_by(:updated_at, :desc).limit(4)
      render :template => '/listings/not_visible.html.erb'
      return
    end

    @account = @listing.try(:account)

    return render :template => '/listings/not_visible.html.erb' if @account.blank?
    @profile = @account.profile

    @main_photo = @listing.get_main_photo
    @listing_images = @listing.listing_images.is_public(user_signed_in?).where(:image.ne => nil).where(:main_photo => false).order_by([[:category, :asc], [:order, :asc]])
    @profile_images = @profile.profile_images.is_public(user_signed_in?).where(:image.ne => nil).order_by([[:category, :asc], [:order, :asc]])

    @exchange_types = ExchangeType.filter_listing_types(@listing.exchange_types)

    @property_details = PropertyDetail.selectable

    @references = @account.get_visible_references
    @wish_list = @account.profile.wish_list_destinations
    @exchange_dates = @listing.exchange_dates.get_all_valid_periods
    @related_listings = Listing.active_account.related(@listing).limit(4)
    @open_for_all = @account.profile.open_for_all_destinations unless @account.profile.open_for_all_destinations.nil?

    if current_user
      @related_listings = @related_listings.only_international(current_user)
      @last_interaction = Conversation.get_last_interaction(current_user, @listing)
    end

    @listing.create_statistics(request)

    respond_to do |format|
      format.html
    end
  end

  def preview
    @listing = Listing.find(params[:id])
    @account = @listing.account
    @profile = @account.profile

    @main_photo = @listing.get_main_photo
    @listing_images = @listing.listing_images.is_public(user_signed_in?).where(:image.ne => nil).where(:main_photo => false).order_by([[:category, :asc], [:order, :asc]])
    @profile_images = @profile.profile_images.is_public(user_signed_in?).where(:image.ne => nil).order_by([[:category, :asc], [:order, :asc]])

    @exchange_types = ExchangeType.filter_listing_types(@listing.exchange_types)

    @property_details = PropertyDetail.selectable
    @open_for_all = @account.profile.open_for_all_destinations unless @account.profile.open_for_all_destinations.nil?
    @references = @account.get_visible_references

    @wish_list = @account.profile.wish_list_destinations
    @exchange_dates = @listing.exchange_dates.get_all_valid_periods
    @related_listings = Listing.active_account.related(@listing).limit(4)
    if current_user
      @related_listings = @related_listings.only_international(current_user)
    end

    respond_to do |format|
      format.html
    end
  end

  def find
    super
    respond_to do |format|
      format.js
    end
  end

  def get_listings
    super
    respond_to do |format|
      format.js {render( json: @listings)}
    end
  end

  def overview
    @listing = Listing.has_permission(current_user).find(params[:id])
    listing_params = ActiveListing.get_validation_params(@listing)
    @active_listing = ActiveListing.new(listing_params)
    @active_listing.valid?

    @account = @listing.account
    @listing_image = ListingImage.new

    @exchange_types = ExchangeType.selectable
    @property_details = PropertyDetail.selectable

    respond_to do |format|
      format.html {render(layout: 'dashboard', template: '/listings/overview.html.erb')}
    end
  rescue Mongoid::Errors::DocumentNotFound
    redirect_to(searches_index_path, {notice: t('errors.listing_not_found')})
  end

  def exchange_settings
    @listing = Listing.has_permission(current_user).find(params[:id])
    @exchange_types = ExchangeType.selectable
    @account = current_user.account
    @profile = @account.profile

    respond_to do |format|
      format.html {render(layout: 'dashboard')}
    end
  end

  def destroy
    @listing = Listing.has_permission(current_user).find(params[:id])
    account_id = @listing.account_id
    @listing.destroy

    respond_to do |format|
      format.html { redirect_to account_listings_url(account_id) }
    end
  end

  def enable
    @listing = Listing.has_permission(current_user).find(params[:id])

    listing_params = ActiveListing.get_validation_params(@listing)
    @active_listing = ActiveListing.new(listing_params)

    respond_to do |format|
      if @active_listing.valid?
        @listing.enable_for_public
        format.html { redirect_to overview_listing_url(@listing), notice: t('alert.listing_available_for_exchange') }
      else
        format.html { render action: "overview" }
      end
    end
  end

  def disable
    @listing = Listing.has_permission(current_user).find(params[:id])
    disabled = @listing.disable_for_public

    respond_to do |format|
      if disabled
        format.html { redirect_to overview_listing_url(@listing), notice: t('alert.listing_no_longer_visible') }
      end
    end
  end

  ##
  # Updates only the availability button using a specific partial
  def set_availability_for_exchange
    @listing = Listing.find(params[:listing_id])
    @account = @listing.account
    availability = params[:availability]
    @listing.set_availability_for_exchange(availability)
    flash[:notice] = t('alert.availability_updated')
    respond_to do |format|
      format.js
      format.html  { redirect_to member_dashboard_url, notice: t('alert.availability_updated') }
    end
  end

  ##
  # Updates both available for exchange and hotlist buttons using a single partial
  def set_availability_with_hotlist
    @listing = Listing.find(params[:listing_id])
    @account = @listing.account
    availability = params[:availability]
    @listing.set_availability_for_exchange(availability)
    flash[:notice] = t('alert.availability_updated')
    respond_to do |format|
      format.js
      format.html  { redirect_to member_dashboard_url, notice: t('alert.availability_updated') }
    end
  end

  ##
  # Landing page for agents and admins when creating a new or seconadary listing for members via the account overview
  def new_listing_as_agent
    @account = Account.find(params[:account_id])
    respond_to do |format|
      format.html {render(layout: 'management')}
    end
  end

  ##
  # Creates a listing setup up by an admin or agent. After listing is created the user is redirected back to the account overview
  def create_listing_as_agent
    @account = Account.find(params[:account_id])
    @country = Country.where(short: @account.country_short).first
    @account.listings.create!(
      account_country_short: @account.country_short,
      country: @country.msgid,
      map_visibility: 'hidden'
    )

    respond_to do |format|
      format.html {redirect_to(account_path(@account))}
    end
  end

  def message_selector
    respond_to do |format|
      format.js
    end
  end

  private

  def valid_listing_params
    params.require(:valid_guide_listing).permit(:headline, :description, :sleeping_capacity, :property_type, :environment, :pets, :children, :property_details, :has_been_completed, :main_photo, :earliest_date, :latest_date, :main_photo_cache)
  end
end
