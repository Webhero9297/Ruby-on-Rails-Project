class Listings::CustomCityAndCountryHeadlinesController < ApplicationController
  layout('management')

  def edit
    @listing = Listing.has_permission(current_user).find(params[:id])

    # Avoiding the main photo validation
    @listing.main_photo_placeholder = true

    respond_to do |format|
      format.html
    end
  end

  def update
    @listing = Listing.has_permission(current_user).find(params[:id])

    # Avoiding the main photo validation
    @listing.main_photo_placeholder = true

    @listing.update_custom_city_and_country(
      params[:listing][:custom_nearest_city],
      params[:listing][:custom_country]
    )

    respond_to do |format|
      if @listing.valid?
	format.html { redirect_to account_path(@listing.account_id), notice: I18n.t('listing.custom_headline_updated') }
      else
	format.html { render(action: 'edit') }
      end
    end
  end
end
