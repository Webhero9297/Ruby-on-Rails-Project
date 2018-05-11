# encoding: utf-8
class FavoritesController < ApplicationController
  filter_access_to :all
  layout "dashboard"

  def index
    l_num  = params[:listing_number]
    m_name = params[:member_name]

    @favorite_listings = current_user.account.get_favorites(l_num, m_name).sort_by(&:country_code)
    @favorite_notes = current_user.account.get_favorite_notes()
    @property_details = PropertyDetail.selectable
  end

  def list
    @favorite_listings = current_user.account.get_favorites()
    @favorite_notes = current_user.account.get_favorite_notes()
    @user_account = current_user.account
    @conversation = Conversation.new
    @subject = ''
    @body_text = ''
    @recipients = {}
  end

  def conversation
    @favorite_listings = current_user.account.get_favorites()
    @favorite_notes = current_user.account.get_favorite_notes()
    @property_details = PropertyDetail.selectable
  end

  def add
    @favorite = Favorite.new
    @listing = Listing.find(params[:listing_id])
    session[:return_url] = request.env["HTTP_REFERER"]
    flash[:notice] = t('alert.added_favorite')

    respond_to do |format|
      format.html
      format.js { current_user.account.add_as_favorite(@listing.id) }
    end
  end

  def remove
    listing_id = params[:listing_id]
    current_user.account.remove_favorite(listing_id)
    return_url = request.env["HTTP_REFERER"]

    respond_to do |format|
      format.html { redirect_to return_url, notice: t('alert.favorite_listing_removed') }
    end
  end

  def remove_favorites
    @listing_ids = params[:favorites]

    return if @listing_ids.nil?

    current_user.account.remove_favorites(@listing_ids)

    @favorites = ''
    @listing_ids.each do |favorite|
      @favorites << "#favorite-card-#{favorite},"
    end

    @favorites = @favorites.chomp(',')

    flash[:notice] = t('alert.favorites_removed')

    respond_to do |format|
      format.js
    end
  end

  def create
    @favorite = current_user.account.add_as_favorite(params[:favorite][:listing_id], params[:favorite][:note])

    return_url = session[:return_url]
    session[:return_url] = nil

    respond_to do |format|
      if @favorite
        format.html { redirect_to return_url, notice: t('alert.listing_added_favorites') }
      else
        format.html { render action: 'add' }
      end
    end
  end

  def update
    @favorite = current_user.account.favorites.where(:_id => params[:id]).first

    respond_to do |format|
      if @favorite
        @favorite.update_attribute(:note, params[:favorite][:note])
        @listing_id = @favorite.listing_id

        flash[:notice] = t('alert.listing_favorite_updated')
        format.html { redirect_to favorites_url }
        format.js
      else
        format.html { render action: 'index' }
      end
    end
  end

  def destroy
    @listing_id = params[:id]
    current_user.account.remove_favorite(@listing_id)
    return_url = request.env["HTTP_REFERER"]

    respond_to do |format|
      flash[:notice] = t('alert.listing_favorite_deleted')
      if params[:list].blank?
        format.html { redirect_to return_url }
        format.js
      else
        format.html { redirect_to return_url }
        format.js { render(template: '/favorites/remove_from_list.js.erb')}
      end
    end
  end
end
