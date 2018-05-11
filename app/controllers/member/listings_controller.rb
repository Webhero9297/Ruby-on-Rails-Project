# encoding: utf-8
class Member::ListingsController < ApplicationController

  filter_access_to :all
  layout "dashboard"
  before_filter :check_subscription
  
  def index
    @listings = current_user.account.listings.all
    @active_listing = ActiveListing.new
    @main_photo_placeholder = false
    
    profile_params = ValidProfile.get_validation_params(current_user.account)
    @valid_profile = ValidProfile.new(profile_params)
    @valid_profile.valid?
    
    respond_to do |format|
      format.html
      format.json { render json: @listings }
    end
  end
  
  
  def new
    @account = current_user.account
    @listing = Listing.new
    @environments = Environment.limit(20)
    @contact_address = ''

    @property_details = PropertyDetail.selectable
    @house_types = HouseType.selectable
    @environments = Environment.selectable

    respond_to do |format|
      if @account.can_create_listing?
        format.html
      else
        format.html {redirect_to member_dashboard_path, notice: t('alert.you_can_not_add_more_listings') }
      end

    end
  end


  def create
    @account = current_user.account

    if not @account.can_create_listing?
      redirect_to member_dashboard_path, notice: t('alert.you_can_not_add_more_listings')
      return
    end

    country = Country.get_by_short(params[:listing][:country_code])
    if country
      params[:listing][:country] = country.msgid
    end

    country = params[:listing][:country_code].blank? ? '' : Country.get_by_short(params[:listing][:country_code])

    @listing = Listing.new(
        headline: params[:listing][:headline],
        description: params[:listing][:description],
        sleeping_capacity: params[:listing][:sleeping_capacity],
        property_type: params[:listing][:property_type],
        environment: params[:listing][:environment],
        main_photo: params[:listing][:main_photo],
        main_photo_cache: params[:listing][:main_photo_cache],
        lat: params[:listing][:lat],
        lng: params[:listing][:lng],
        street: params[:listing][:street],
        postal_town: params[:listing][:postal_town],
        postal_code: params[:listing][:postal_code],
        state: params[:listing][:state],
        state_long: params[:listing][:state_long],
        country: params[:listing][:country],
        country_code: params[:listing][:country_code],
        google_formatted_address: params[:listing][:google_formatted_address],
        property_details: [params[:listing][:children], params[:listing][:pets]],
        searchable: true, # Set for legacy purposes
        has_been_completed: true, # Set for legacy purposes
        main_photo_placeholder: params[:main_photo_placeholder]
    )

    respond_to do |format|
      if @listing.valid?
        @account.listings << @listing

        if !params[:main_photo_placeholder].blank? && params[:listing][:main_photo_cache].blank? && params[:listing][:main_photo].blank?
          @listing.main_photo.store!(File.open(Listing::LISTING_PLACEHOLDER_IMAGES[params[:main_photo_placeholder].to_sym]))
        end

        @listing.save
        @listing.set_account_data_on_listing
        format.html { redirect_to preview_listing_path(@listing), notice: t('alert.listing_created') }
      else
        @environments = Environment.limit(20)
        @contact_address = params[:q]
        @property_details = PropertyDetail.selectable
        @house_types = HouseType.selectable
        @environments = Environment.selectable
        @contact_address = params[:listing][:google_formatted_address]
        @main_photo_placeholder = params[:main_photo_placeholder].blank? ? nil : params[:main_photo_placeholder]
        format.html { render action: 'new'}
      end
    end
  end

  private
  
  def listing_params
    params.require(:listing).permit(:headline, :description, :sleeping_capacity, :property_type, 
                                    :environment, :property_details, :has_been_completed, 
                                    :main_photo, :main_photo_cache, :earliest_date, :latest_date,
                                    :lat, :lng, :street ,:postal_town ,:postal_code,
                                    :state ,:state_long ,:country ,:country_code ,:google_formatted_address)

  
  end
end
