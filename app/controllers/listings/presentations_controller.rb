# encoding: UTF-8
class Listings::PresentationsController < ApplicationController
  filter_access_to :all
  layout "dashboard"

  def show
    @listing = Listing.has_permission(current_user).find(params[:listing_id])
    @listing_images = @listing.listing_images.get_by_category(['home']).order_by([[:order, :asc]])
    @listing_image = ListingImage.new

    respond_to do |format|
      format.html
    end
  end

  def edit
    @listing = Listing.has_permission(current_user).find(params[:listing_id])

    respond_to do |format|
      format.js
    end
  end

  def update
    @listing = Listing.has_permission(current_user).find(params[:listing_id])

    respond_to do |format|
      @listing.set(:description, params[:listing][:property][:description])
      @listing.set_last_updated
      flash[:success] = t('alert.home_description_updated')
      format.js
    end
  end


  def cancel
    @listing = Listing.has_permission(current_user).find(params[:listing_id])

    respond_to do |format|
      format.js {render(template: '/listings/presentations/update.js.erb')}
    end
  end

  private

  def description_params
    params[:listing][:property].permit(:description)
  end
end
