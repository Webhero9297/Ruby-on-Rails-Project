# encoding: UTF-8
class Mobile::ListingsController < ApplicationController
  filter_access_to :all
  layout 'mobile'
  before_filter :set_as_mobile

  def index
    @screen_title = 'Listings'
    @countries = Country.sorted_by_language

    session[:device_filter_params] = {dc: params[:dc], page: params[:page]}

    if params[:dc].nil?
      vip_countries = Country.get_shorts_as_array('vip')
      vip_countries = vip_countries.sample(60)
      if user_signed_in?
        @listings = Listing.active_account.only_international(current_user).where(:country_code.in => vip_countries).order_by(:updated_at, :desc).page(params[:page]).per(10)
      else
        @listings = Listing.active_account.where(:country_code.in => vip_countries).order_by(:updated_at, :desc).page(params[:page]).per(10)
      end
    else
      @destination_country = params[:dc].upcase
      if user_signed_in?
        @listings = Listing.active_account.only_international(current_user).where(country_code: @destination_country).order_by(:updated_at, :desc).page(params[:page]).per(10)
      else
        @listings = Listing.active_account.where(country_code: @destination_country).order_by(:updated_at, :desc).page(params[:page]).per(10)
      end
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
    @screen_title = 'Listings'

    # Another really ugly hack to please jQuery mobile, I hate jQuery mobile
    # Builds the correct back url when going back to a search / filter result after viewing a listing
    begin
      @back_url = mobile_listings_path(dc: session[:device_filter_params][:dc], page: session[:device_filter_params][:page])
    rescue Exception
      @back_url = mobile_listings_path
    end

    @listing = Listing.find(params[:id])
    @profile = @listing.account.profile

    @exchange_types = @listing.get_exchange_types
    @allowed_property_details = @listing.get_allowed_property_details

    respond_to do |format|
      format.html
    end
  rescue Mongoid::Errors::DocumentNotFound
    redirect_to(searches_index_path, {notice: t('errors.listing_not_found')})
  end

  def gallery
    begin
      @screen_title = 'Listings'

      @listing = Listing.find(params[:id])
      @profile = @listing.account.profile

      if user_signed_in?
        @photos = @listing.get_images_by_all_categories
        @photos += @profile.profile_images.order_by(:order, :asc)
      else
        @photos = @listing.get_images_by_all_categories.is_public(user_signed_in?).order_by(:order, :asc)
        @photos += @profile.profile_images.is_public(user_signed_in?).order_by(:order, :asc)
      end

      respond_to do |format|
        format.html
      end
    rescue Mongoid::Errors::DocumentNotFound
      respond_to do |format|
        format.html { redirect_to mobile_listings_path }
      end
    end
  end
end
