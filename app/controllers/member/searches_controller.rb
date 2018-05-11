# encoding: UTF-8
class Member::SearchesController < Base::BaseListingController
  
  filter_access_to :all
  layout "application"
  before_filter :check_subscription

  
  def show
    @property_details = PropertyDetail.limit(100)
    @listing = Listing.find(params[:id])
    @related_listings = Listing.searchable.only_international(current_user).related(@listing).limit(4)
    @listing.create_statistics(request)
    
    profile_params = ValidProfile.get_validation_params(current_user.account)
    @valid_profile = ValidProfile.new(profile_params)
    
    respond_to do |format|
      if @valid_profile.valid? then
        format.html
      else
        format.html
      end
    end
  end

  def set_match_alert
    search = current_user.account.get_search(params[:id])
    search.set_match_alert(params[:status])
    render :nothing => true
  end
end
