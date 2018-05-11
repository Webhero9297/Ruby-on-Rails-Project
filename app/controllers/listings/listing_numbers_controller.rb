class Listings::ListingNumbersController < ApplicationController
  layout('management')

  def edit
    @listing = Listing.has_permission(current_user).find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def update
    @listing = Listing.has_permission(current_user).find(params[:id])
    @listing.update_listing_number(params[:listing][:listing_number])
    respond_to do |format|
      if @listing.valid?
	format.html { redirect_to account_path(@listing.account_id), notice: t("listing.listing_number_updated") }
      else
	format.html {render(action: 'edit')}
      end
    end
  end
end
