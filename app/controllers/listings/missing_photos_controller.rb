class Listings::MissingPhotosController < ApplicationController
  layout "dashboard"
  def index
    @listings = current_user.account.listings
    respond_to do |format|
      format.html
    end
  end

  def update
    photos = params['photo']
    count = 0
    delete_count = 0
    listing = Listing.find(params['listing_id'])

    if photos and photos.length > 0
      photos.each do |photo|
  	id    = photo[0]
  	value = photo[1]

  	next if value == 'undecided'

  	if value == 'add'
  	  listing.listing_images.where(:_id => id).update_all(category: 'home')
  	  count += 1
  	  next
  	end

  	if value == 'delete'
  	  listing.listing_images.where(:_id => id).delete_all
          delete_count += 1
  	end
      end
    end

    images = listing.get_images_by_category(['hidden'])
    respond_to do |format|
      if images.count > 0
  	format.html { redirect_to(overview_listing_url(listing, :anchor => 'images'), {notice: "You added #{count} photos and deleted #{delete_count} photos."}) }
      else
  	format.html { redirect_to(overview_listing_url(listing, :anchor => 'images'), {notice: "You added #{count} photos and deleted #{delete_count} photos."}) }
      end
    end
  end
end
