# encoding: utf-8
class Mobile::FavoritesController < ApplicationController

  filter_access_to :all
  layout 'mobile'
  before_filter :set_as_mobile

  def index
    @screen_title = 'Favorites'
    @favorites = current_user.account.get_favorites() 

    respond_to do |format|
      format.html
    end
  end

  def show
    @screen_title = 'Favorites'

    @listing = Listing.find(params[:listing_id])
    @profile = @listing.account.profile
    
    @exchange_types = @listing.get_exchange_types
    @allowed_property_details = @listing.get_allowed_property_details

    respond_to do |format|
      format.html
    end
  end
  

  def add
    @listing_id = params[:listing_id]
    current_user.account.add_as_favorite(params[:listing_id])
    
    respond_to do |format|
      format.js
    end  
  end


  def remove
    @listing_id = params[:listing_id]
    current_user.account.remove_favorite(params[:listing_id])
    
    respond_to do |format|
      format.js
    end
  end
  
end
