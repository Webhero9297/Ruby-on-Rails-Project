# encoding: utf-8
class Listing::ImagesController < ApplicationController
  filter_access_to :all
  layout "dashboard"
  before_filter :check_subscription

  def index
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @main_photo = @listing.get_main_photo
    @listing_images = @listing.get_images_by_category(['home', 'surroundings'])

    @listing_image = ListingImage.new

    respond_to do |format|
      format.html
    end
  end

  def show
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @listing_image = @listing.listing_images.find(params[:id])

    respond_to do |format|
      format.js
    end
  end

  def edit
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @listing_image = @listing.listing_images.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def create
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @main_photo = @listing.get_main_photo
    @exterior_images = @listing.get_images_by_category(['exterior'])
    @interior_images = @listing.get_images_by_category(['home'])

    @listing_image = @listing.listing_images.new(:category => params[:category])
    @listing_image.image = params[:file]

    respond_to do |format|
      if @listing_image.valid?
        @listing_image.save
        @listing.set_last_updated
        format.html { redirect_to(listing_images_url(@listing), {notice: t('alert.image_successfully_uploaded')}) }
        format.js { render( :json => {:html => render_to_string(partial: 'listing/images/listing_image', object: @listing_image, as: 'image', locals: {listing: @listing})}, :status => 200)}

      else
        format.html { render( action: 'index') }
        format.js { render( :json => {:error => 'validation failed', :image => @listing_image.errors.full_messages}, :status => 202 )}
      end
    end
  end

  def update
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @listing_image = @listing.listing_images.find(params[:id]).update_image(listing_image_params)
    @listing.set_last_updated
    respond_to do |format|
      format.html { redirect_to(listing_images_url(@listing), {notice: t('alert.image_successfully_updated')}) }
    end
  end

  def upload_main_photo
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @listing_image = @listing.listing_images.new(:category => 'home')
    @listing_image.image = params[:file]

    respond_to do |format|
      if @listing_image.valid?
        @listing_image.save
        @listing_image.set_as_main
        @listing.set_last_updated
        format.html { redirect_to(listing_images_url(@listing), {notice: t('alert.image_successfully_uploaded')}) }
        format.js { render( :json => {:html => render_to_string(partial: 'listing/images/upload_main_photo', object: @listing_image, as: 'image', locals: {listing: @listing})}, :status => 200)}
      else
        format.html { render( action: 'index') }
        format.js { render( :json => {:error => 'validation failed', :image => @listing_image.errors.full_messages}, :status => 202 )}
      end
    end
  end

  def upload_photo
    @listing = Listing.new
    @listing_image = ListingImage.new(:category => 'home')
    @listing_image.image = params[:file]

    respond_to do |format|
      if @listing_image.valid?
        @listing_image.save
        @listing_image.set_as_main
        format.html { redirect_to(listing_images_url(@listing), {notice: t('alert.image_successfully_uploaded')}) }
        format.js { render( :json => {:html => render_to_string(partial: 'listing/images/upload_main_photo', object: @listing_image, as: 'image', locals: {listing: @listing})}, :status => 200)}
      else
        format.html { render( action: 'index') }
        format.js { render( :json => {:error => 'validation failed', :image => @listing_image.errors.full_messages}, :status => 202 )}
      end
    end
  end

  ##
  # Handles the setting and removing of main photo.
  # Only images of the home category are able to be main photo
  def set_as_main
    @listing = Listing.has_permission(current_user).find(params[:listing_id])

    # we can't set as main if the listing_image doesn't exist
    begin
      @listing_image = @listing.listing_images.find(params[:id])
      @listing_image.set_as_main
    rescue Mongoid::Errors::DocumentNotFound
      @listing_image = nil
    end

    @listing_images = @listing.listing_images.get_by_category(['home']).order_by([[:order, :asc]])

    flash.now[:success] = t('listings.images.notice.main_photo_set')
    respond_to do |format|
      format.js
      format.html { redirect_to(listing_presentations_path(@listing), {notice: t('listings.images.notice.main_photo_set')}) }
    end
  end

  def set_public
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @listing_image = @listing.listing_images.find(params[:id])
    @listing_image.set_public()
    respond_to do |format|
      format.js {render( template: 'listing/images/reload_image.js.erb')}
      format.html { redirect_to(listing_images_url(@listing), {notice: t('alert.image_successfully_updated')}) }
    end
  end

  def rotate_left
    rotate :left
  end

  def rotate_right
    rotate :right
  end

  def rotate_main_photo_left
    rotate_main_photo :left
  end

  def rotate_main_photo_right
    rotate_main_photo :right
  end

  def set_private
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @listing_image = @listing.listing_images.find(params[:id])
    @was_main_photo = @listing_image.main_photo
    @listing_image.set_private()
    respond_to do |format|
      format.js {render( template: 'listing/images/reload_image.js.erb')}
      format.html { redirect_to(listing_images_url(@listing), {notice: t('alert.image_successfully_updated')}) }
    end
  end

  def set_order
    listing = Listing.has_permission(current_user).find(params[:listing_id])
    images_list = params[:images_list]
    listing.listing_images.set_order(images_list)
    render :nothing => true
  end

  def edit_caption
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @listing_image = @listing.listing_images.find(params[:id])
    respond_to do |format|
      format.js
    end
  end

  def cancel_caption
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @listing_image = @listing.listing_images.find(params[:id])
    respond_to do |format|
      format.js
    end
  end

  def update_caption
    @listing = Listing.has_permission(current_user).find(params[:listing_id])

    begin
      @listing_image = @listing.listing_images.find(params[:id]).update_caption(listing_image_params[:caption])
    rescue Mongoid::Errors::DocumentNotFound
      @listing_image = nil
    end

    respond_to do |format|
      format.js
    end
  end

  def get_images
    @category = params[:category]
    @size = params[:size]
    @listing = Listing.find(params[:listing_id])
    @images = @listing.get_images_by_category([@category])
    respond_to do |format|
      if @size == 'large'
        format.js { render(template: 'listing/images/get_images_large.js.erb') }
      end

      if @size == 'small'
        format.js { render(template: 'listing/images/get_images_small.js.erb') }
      end
    end
  end

  def destroy
    begin
      @listing = Listing.has_permission(current_user).find(params[:listing_id])
      @listing_image = @listing.listing_images.find(params[:id])
      @was_main_photo = @listing_image.main_photo
      @listing_image.destroy
      flash.now[:success] = t('notice.image_was_deleted')
    rescue Mongoid::Errors::DocumentNotFound
      # in case any document doesn't exist we just consider as deleted
    end
    respond_to do |format|
      format.html { redirect_to(listing_images_url(@listing), {notice: t('notice.image_was_deleted')}) }
      format.js
    end
  end

  # FIXME: It should be extracted to an external module with the
  # common methods for anything related to photos and uploads for a
  # listing (merge with profile_images_controller)
  def rotate direction
    @listing = Listing.has_permission(current_user).find(params[:listing_id])

    begin
      @listing_image = @listing.listing_images.find(params[:id])
      @listing_image.rotate direction
      flash[:notice] = t('alert.image_successfully_updated')
      flash.keep(:notice)
    rescue Mongoid::Errors::DocumentNotFound
      # a listing image must be found to be rotated
    end

    respond_to do |format|
      # pretty ugly, huh? For now it is the best way to just refresh
      # the page when the image is changed.
      format.js { render js: "window.location.reload();" }
      format.html { redirect_to(listing_images_url(@listing)) }
    end
  end

  def rotate_main_photo direction
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @listing.rotate_main_photo direction

    respond_to do |format|
      flash[:notice] = t('alert.image_successfully_updated')
      flash.keep(:notice)

      # pretty ugly, huh? For now it is the best way to just refresh
      # the page when the image is changed.
      format.js { render js: "window.location.reload();" }
      format.html { redirect_to :back }
    end
  end

  private

  def listing_image_params
    params.require(:listing_image).
      permit(:caption, :category, :publicly_visible, :main_photo)
  end
end
