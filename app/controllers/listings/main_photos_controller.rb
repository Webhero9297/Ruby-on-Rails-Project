# encoding: UTF-8
class Listings::MainPhotosController < ApplicationController
  layout 'dashboard'

  def upload
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @listing.main_photo = params[:file]
    @listing.main_photo_caption = ''

    respond_to do |format|
      if @listing.valid?
        @listing.save
        @listing.set_last_updated
        @listing.add_main_photo_to_image_set
        format.js {
          render(
            :json => {
              :html => render_to_string(partial: 'main_photo', locals: {listing: @listing, main_photo: @listing.get_main_photo })
            }, :status => 200
          )
        }
      else
        format.js {
          render(
            :json => {
              :error => 'validation failed', :image => @listing.errors.full_messages
            }, :status => 202
          )
        }
      end
    end
  end

  def edit_caption
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    respond_to do |format|
      format.js
    end
  end

  def update_caption
    caption = params[:listing][:main_photo_caption]
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @listing.set(:main_photo_caption, caption)
    @listing.listing_images.set_caption_main_photo(caption)
    @listing.set_last_updated
    flash[:notice] = t('alert.caption_updated')
    respond_to do |format|
      format.js
    end
  end

  def cancel_caption
    respond_to do |format|
      format.js
    end
  end
end
