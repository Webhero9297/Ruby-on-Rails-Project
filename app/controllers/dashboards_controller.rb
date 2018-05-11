# encoding: UTF-8
class DashboardsController < ApplicationController
  filter_access_to :all
  before_filter { |c| c.set_dashboard_scope 'member' }
  before_filter :check_subscription
  layout "dashboard"

  def index
    @account = current_user.account
    @account.listings.each do |listing|
      listing.set_account_data_on_listing
    end
    country = current_user.account.country_short
    @national_representative = User.get_agent_profiles_for_country(country)
    @listings = @account.listings.all

    @exchange_approval_requests = @account.exchange_approval_requests?

    # We show different info on dashboard if only one listing
    # Statistics does not need to be pregenerated when one listing
    if @listings.count == 1
      @onelisting = @listings.first
      @top_visitors = @onelisting.top_visitors(5)
      @top_countries = @onelisting.top_countries(5)
    else
      @statistics = {}
      @account.listings.each do |listing|
        @statistics[listing.id] = {:total => listing.count_per_date().count.to_i, :week => listing.count_per_date(7).count.to_i}
      end
    end

    @has_hidden_photos = false
    has_hidden = Listing.where(account_id: @account.id).where(:listing_images.matches => {:category => 'hidden'}).first
    if has_hidden
      @has_hidden_photos = true
    end


    exchange_agreements = ExchangeAgreement.by_owner(@account.id).active.future_dates.order_by([[:created_at, :asc]]).where(:show_notification => @account.id)
    @exchange_activities = []
    exchange_agreements.each do |ea|
      last_activity = ea.new_activity_check(@account.id)
      if last_activity
        @exchange_activities.push(last_activity)
      end
    end


    progress_params = ProfileProgress.get_progress_params(@account)
    @profile_progress = ProfileProgress.new(progress_params)

    # Calculate messages differently when you are an agent.
    # We only want to show those agent messages that was started from the users.
    if current_user.is_agent
      @unread_messages = Conversation.any_of({:kind => 'member_to_member'}, {:kind.in => ['member_to_agent', 'agent_to_member'], :started_by => current_user.account.id}).all_in(participants: [current_user.account.id]).not_in(archived: [current_user.account.id]).not_in(read_by: [current_user.account.id]).where(:messages.exists => true)
      @unread_messages = @unread_messages.count
    else
      @unread_messages = Conversation.get_number_of_unread_conversations(current_user)
    end




    profile_params = ValidProfile.get_validation_params(@account)
    @valid_profile = ValidProfile.new(profile_params)

    respond_to do |format|
      if @valid_profile.valid?
        format.html
      else
        format.html {redirect_to( action: "profile_address" )}
      end
    end
  end

  def profile_address
    session[:guide] = 'profile'
    @account = current_user.account
    @languages = Language.all
    @valid_guide_profile = ValidGuideProfile.new(
      address: @account.contact.address,
      postal_code: @account.contact.postal_code,
      postal_town: @account.contact.postal_town,
      county: @account.contact.county,
      telephone: @account.contact.telephone,
      mobile: @account.contact.mobile,
      time_zone: 'UTC'
    )

    respond_to do |format|
      format.html
    end
  end


  def save_profile_address
    @account = current_user.account
    @languages = Language.all

    @valid_guide_profile = ValidGuideProfile.new(valid_guide_params)

    respond_to do |format|
      if @valid_guide_profile.valid?

        @account.contact.update_attributes(
          birthdate: params[:valid_guide_profile][:birthdate],
          address: params[:valid_guide_profile][:address],
          postal_code: params[:valid_guide_profile][:postal_code],
          postal_town: params[:valid_guide_profile][:postal_town],
          county: params[:valid_guide_profile][:county],
          telephone: params[:valid_guide_profile][:telephone],
          mobile: params[:valid_guide_profile][:mobile]
        )

        @account.profile.set_spoken_languages( params[:valid_guide_profile][:spoken_languages] )
        @account.time_zone = params[:valid_guide_profile][:time_zone]
        @account.save

        format.html { redirect_to(member_dashboard_url, notice: t('alert.after_saved_profile_address')) }
      else
        format.html { render action: "profile_address" }
      end
    end
  end

  ##
  # Searches for members by name, used by the find by member name search on the members landing page.
  def find_member_by_name
    @member_name = params[:member_name]
    @results = Account.active_account.find_by_name(@member_name)

    respond_to do |format|
      format.html
    end
  end

  ##
  # Searches for members by name, used by the find by member name search on the members landing page.
  def find_member_by_number
    @listing_number = params[:listing_number].upcase
    @results = Account.active_account.find_by_listing_number(@listing_number)

    respond_to do |format|
        format.html {render template: "dashboards/find_member_by_name"}
    end
  end

  ##
  # Makes and extra redirect and resets the switch user session so the agent or admin can't "switch" back to themselves
  def member_dashboard_for_management
    if session[:management_user_id] == current_user.id
      session[:management_user_id] = nil
    end
    respond_to do |format|
      format.html {redirect_to(member_dashboard_path)}
    end
  end


  def information_page
    respond_to do |format|
      format.html
    end
  end


  def information_search
    respond_to do |format|
      format.html
    end
  end

  private

  def valid_guide_params
    params.require(:valid_guide_profile).permit(:address, :postal_code, :postal_town, :county, :telephone, :mobile, :time_zone, :spoken_languages => [])
  end

end
