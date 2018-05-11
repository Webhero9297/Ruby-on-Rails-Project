# encoding: UTF-8
class Member::ExchangeAgreementsController < ApplicationController
  
  filter_access_to :all
  layout "dashboard"
  before_filter :check_subscription
  
  def index
    account_id = current_user.account.id

    @exchange_agreements = ExchangeAgreement.by_owner(account_id).active.order_by([["agreements.start_date", -1]]) 
    
    active = []
    @exchange_agreements.each do |exchange_agreement|
      if Account.exists?(conditions: {_id: exchange_agreement.get_partner_account_id(account_id)})
        active.append(exchange_agreement)
      end
    end
    @exchange_agreements = active

    @listings = current_user.account.listings.all
    
    profile_params = ValidProfile.get_validation_params(current_user.account)
    @valid_profile = ValidProfile.new(profile_params)
    @valid_profile.valid?
    
    respond_to do |format|
      format.html
    end
  end
  
  
  def new
    @exchange_partner = ExchangePartner.new
    @favorites = current_user.account.get_favorites()
    @my_listings = current_user.account.listings
    
    respond_to do |format|
      format.html
    end
  end

  ##
  # Searches for members by name, used by the find by member name search on the members landing page.
  def find_partner_by_number
    @listing_number = params[:listing_number].upcase
    @results = Listing.find_by_listing_number(@listing_number)

    respond_to do |format|
        format.js
    end
  end
  
  
  def show
    
    # Additional where cluase to make sure no one else than the logged in user can view the agreement
    exchange_agreement = ExchangeAgreement.where('agreements.owner' => current_user.account.id).find(params[:id])
    @member_agreement = exchange_agreement.agreements.where(owner: current_user.account.id).first
    
    partner_id = exchange_agreement.get_partner_account_id(current_user.account.id)
    @partner_agreement = exchange_agreement.agreements.where(owner: partner_id).first
    
    @member = current_user.account
    @partner = Account.unscoped.find(partner_id)
    @exchange_agreement = exchange_agreement
    
    exchange_agreement.create_activity('viewed', current_user)
    respond_to do |format|
      format.html
    end

  end
  
  def overview
    
    # Additional where clause to make sure no one else than the logged in user can view the agreement
    exchange_agreement = ExchangeAgreement.where('agreements.owner' => current_user.account.id).find(params[:id])
    @member_agreement = exchange_agreement.agreements.where(owner: current_user.account.id).first
    
    partner_id = exchange_agreement.get_partner_account_id(current_user.account.id)
    @partner_agreement = exchange_agreement.agreements.where(owner: partner_id).first
    
    @member = current_user.account
    @partner = Account.unscoped.find(partner_id)
    @exchange_agreement = exchange_agreement
    @statuses = {'started'=>20, 'ready_for_review'=>30,'negotiating'=>50, 'accepted'=>75, 'signed'=>90, 'agreed'=>100}

    exchange_agreement.pull(:show_notification, current_user.account.id)

    exchange_agreement.create_activity('viewed', current_user)
    respond_to do |format|
      format.html
    end

  end


  def start
    @exchange_partner = ExchangePartner.new(params[:exchange_partner])
    # TODO Handle multiple listings
    @member_listings = current_user.account.listings
    
    respond_to do |format|
      if @exchange_partner.valid?
        @partner_listing = Listing.get_by_number(params[:exchange_partner][:listing_number])
        format.html
      else
        format.html {render( action: 'new')}
      end
    end
  end
  
  
  def create
    
    @member_listing = Listing.get_by_id(params[:member_listing_id])
    @partner_listing = Listing.get_by_id(params[:partner_listing_id])
    
    exchange_agreement = ExchangeAgreement.build_agreement(@member_listing, @partner_listing)
    
    partner_account = @partner_listing.account
    
    respond_to do |format|
      if partner_account.id  == current_user.account.id
        format.html { redirect_to( member_exchange_agreements_url, notice: t('exchange_agreement.alert.can_not_start_with_own_listing') ) }
      end
      if exchange_agreement.save
        exchange_agreement.create_activity('started', current_user)
        exchange_agreement.add_to_set(:show_notification, partner_account.id)
        # Sends a initial mail that the current user has started an exchange agreement
        NotificationMailer.exchange_agreement_started(partner_account, current_user.account, exchange_agreement).deliver
        format.html { redirect_to( overview_member_exchange_agreement_path(exchange_agreement), notice: t('exchange_agreement.alert.agreement_started') ) }
      else
        format.html { render( action: :start )}
      end
    end
  end
  
  
  def edit
    
    # Additional where cluase to make sure no one else than the logged in user can view the agreement
    @exchange_agreement = ExchangeAgreement.where('agreements.owner' => current_user.account.id).find(params[:id])
    @member_agreement = @exchange_agreement.agreements.where(owner: current_user.account.id).first
    
    partner_id = @exchange_agreement.get_partner_account_id(current_user.account.id)
    @partner_agreement = @exchange_agreement.agreements.where(owner: partner_id).first
    
    @member = current_user.account
    @partner = Account.find(partner_id)
    
    @exchange_agreement.create_activity('viewed', current_user)

    start_year = Time.now.year
    end_year = start_year + 3.years
    @years = "#{start_year}:#{end_year}"

    respond_to do |format|
      format.html
    end
  end
  
  
  def sign
    exchange_agreement = ExchangeAgreement.where('agreements.owner' => current_user.account.id).find(params[:id])
    exchange_agreement.sign(current_user)
    partner_id = exchange_agreement.get_partner_account_id(current_user.account.id)

    exchange_agreement.add_to_set(:show_notification, partner_id)
    respond_to do |format|
      if exchange_agreement.status == 'agreed'
        format.html { redirect_to( future_member_exchange_agreements_url, notice: t('exchange_agreement.alert.agreement_signed') ) }
      else
        format.html { redirect_to( member_exchange_agreements_url, notice: t('exchange_agreement.alert.agreement_signed') ) }
      end
    end
  end

  def handle_term
    
    # Additional where clause to make sure no one else than the logged in user can view the agreement
    exchange_agreement = ExchangeAgreement.where('agreements.owner' => current_user.account.id).find(params[:id])
    member_agreement = exchange_agreement.agreements.where(owner: current_user.account.id).first
    
    partner_id = exchange_agreement.get_partner_account_id(current_user.account.id)
    @partner_agreement = exchange_agreement.agreements.where(owner: partner_id).first
    
    term_hash = { 'car_exchange' => @partner_agreement.car_exchange,
                  'cleaning' => @partner_agreement.cleaning,
                  'long_distance_calls' => @partner_agreement.long_distance_calls,
                  'key_exchange' => @partner_agreement.key_exchange,
                  'pets' => @partner_agreement.pets,
                  'other' => @partner_agreement.other}
    term_name = params[:term_name]
    
    term = term_hash[term_name]
    reason_blank = false
    
    if params[:choice] == 'accept'
      term.accepted_by_partner = true
      term.save!
      exchange_agreement.create_activity('term_accepted', current_user)
    end
    
    if params[:choice] == 'decline'
      if params[:reason].blank?
        reason_blank = true
      else
        term.accepted_by_partner = false
        term.reason = params[:reason]
        term.save!
        exchange_agreement.create_activity('term_declined', current_user)
      end
    end
    # Clear signed by
    exchange_agreement.set(:signed_by, [])
    exchange_agreement.set(:status, 'negotiating')
    
    @term_name = term_name

    flash.now[:success] = t('alert.term_updated')
    respond_to do |format|
      if reason_blank
        format.js {render :template => 'member/exchange_agreements/handle_terms_blank'}
      else
        format.js
      end
    end
  end

  def view_partner_terms
    
    # Additional where cluase to make sure no one else than the logged in user can view the agreement
    @exchange_agreement = ExchangeAgreement.where('agreements.owner' => current_user.account.id).find(params[:id])
    @member_agreement = @exchange_agreement.agreements.where(owner: current_user.account.id).first
    
    partner_id = @exchange_agreement.get_partner_account_id(current_user.account.id)
    @partner_agreement = @exchange_agreement.agreements.where(owner: partner_id).first
    
    @member = current_user.account
    @partner = Account.find(partner_id)

    @exchange_agreement.create_activity('viewed', current_user)
    respond_to do |format|
      format.html
    end
  end


  def read_only_partner_terms
    
    # Additional where cluase to make sure no one else than the logged in user can view the agreement
    exchange_agreement = ExchangeAgreement.where('agreements.owner' => current_user.account.id).find(params[:id])
    @member_agreement = exchange_agreement.agreements.where(owner: current_user.account.id).first
    
    partner_id = exchange_agreement.get_partner_account_id(current_user.account.id)
    @partner_agreement = exchange_agreement.agreements.where(owner: partner_id).first
    
    @member = current_user.account
    @partner = Account.find(partner_id)
    
    respond_to do |format|
      format.html
    end
  end


  def read_only_my_terms
    
    # Additional where cluase to make sure no one else than the logged in user can view the agreement
    @exchange_agreement = ExchangeAgreement.where('agreements.owner' => current_user.account.id).find(params[:id])
    @member_agreement = @exchange_agreement.agreements.where(owner: current_user.account.id).first
    
    partner_id = @exchange_agreement.get_partner_account_id(current_user.account.id)
    @partner_agreement = @exchange_agreement.agreements.where(owner: partner_id).first
    
    @member = current_user.account
    @partner = Account.find(partner_id)


    
    respond_to do |format|
      format.html
    end
  end

  
  def send_to_partner
    exchange_agreement = ExchangeAgreement.where('agreements.owner' => current_user.account.id).find(params[:id])
    member_agreement = exchange_agreement.agreements.where(owner: current_user.account.id).first
    member_agreement.sent = true
    member_agreement.save
    
    exchange_agreement.status = 'negotiating'
    exchange_agreement.save

    partner_id = exchange_agreement.get_partner_account_id(current_user.account.id)
    partner_account = Account.find(partner_id)

    exchange_agreement.add_to_set(:show_notification, partner_id)
    
    NotificationMailer.exchange_agreement(partner_account, current_user.account, exchange_agreement).deliver
    respond_to do |format|
        format.html { redirect_to( overview_member_exchange_agreement_url(exchange_agreement), notice: t('exchange_agreement.alert.terms_sent_to_partner') ) }
    end
  end
  
  
  def update
    exchange_agreement = ExchangeAgreement.where('agreements.owner' => current_user.account.id).find(params[:id])
    @member_agreement = exchange_agreement.agreements.where(owner: current_user.account.id).first
    partner_id = exchange_agreement.get_partner_account_id(current_user.account.id)
    @partner_agreement = exchange_agreement.agreements.where(owner: partner_id).first
    @partner_agreement.update_attributes(params[:partner_terms])
    
    @member_agreement.clear_all()
    @member_agreement.sent = false
    @member_agreement.save
    
    if @member_agreement.is_ready_for_review?
      exchange_agreement.status = 'ready_for_review'
      exchange_agreement.save
    end
    
    # Make sure we have a participants key
    params[:agreement][:participants] = params[:agreement][:participants] || []
    
    # Clear signed by
    exchange_agreement.set(:signed_by, [])
    respond_to do |format|
      if @member_agreement.update_attributes(exchange_agreement_params)
        @member_agreement.set(:participants, params[:agreement][:participants])
        exchange_agreement.create_activity('updated', current_user)

        if params[:agreement][:save_and_complete] == 'true'
          exchange_agreement.set_as_agreed()
        end
        format.html { redirect_to( overview_member_exchange_agreement_url(exchange_agreement), notice: t('exchange_agreement.alert.agreement_updated') ) }
      else
        @exchange_agreement = exchange_agreement

        partner_id = @exchange_agreement.get_partner_account_id(current_user.account.id)
   
        @member = current_user.account
        @partner = Account.find(partner_id)

        format.html { render action: "edit" }
      end
    end
  end
  
  
  def edit_my_terms
    exchange_agreement = ExchangeAgreement.where('agreements.owner' => current_user.account.id).find(params[:id])
    @member_agreement = exchange_agreement.agreements.where(owner: current_user.account.id).first
    
    partner_id = exchange_agreement.get_partner_account_id(current_user.account.id)
    @partner_agreement = exchange_agreement.agreements.where(owner: partner_id).first
    
    @member = current_user.account
    @partner = Account.find(partner_id)

    start_year = Time.now.year
    end_year = start_year + 3.years
    @years = "#{start_year}:#{end_year}"

    
  end
  
  def review_done
    exchange_agreement = ExchangeAgreement.where('agreements.owner' => current_user.account.id).find(params[:id])
    partner_id = exchange_agreement.get_partner_account_id(current_user.account.id)
    partner_account = Account.find(partner_id)
    NotificationMailer.exchange_agreement(partner_account, current_user.account, exchange_agreement).deliver
    
    partner_agreement = exchange_agreement.agreements.where(owner: partner_id).first
    if partner_agreement.has_rejections?
      # Clear sent to
      partner_agreement.set(:sent, false)
    end
    
    member_agreement = exchange_agreement.agreements.where(owner: current_user.account.id).first
    if partner_agreement.all_terms_accepted? and member_agreement.all_terms_accepted?
      exchange_agreement.status = 'accepted'
      exchange_agreement.save
    end
    exchange_agreement.add_to_set(:show_notification, partner_id)
    respond_to do |format|
      format.html { redirect_to( overview_member_exchange_agreement_url(exchange_agreement), notice: t('exchange_agreement.alert.review_completed') ) }
    end
  end

  
  def cancel
    
    exchange_agreement = ExchangeAgreement.where('agreements.owner' => current_user.account.id).find(params[:id])
    
    respond_to do |format|
      if exchange_agreement.cancel(current_user) then
        format.html { redirect_to( member_exchange_agreements_url, notice: t('exchange_agreement.alert.agreement_cancelled') ) }
      else
        format.html { redirect_to( member_exchange_agreements_url, notice: t('exchange_agreement.alert.only_pending_ongoing_can_be_cancelled') ) }
      end
    end
  end
  
  
  def past
    
    account_id = current_user.account.id
    @exchange_agreements = ExchangeAgreement.by_owner(account_id).past
    active = []
    @exchange_agreements.each do |exchange_agreement|
      if Account.exists?(conditions: {_id: exchange_agreement.get_partner_account_id(account_id)})
        active.append(exchange_agreement)
      end
    end

    @exchange_agreements = active
    
    respond_to do |format|
      format.html
    end
  end
  
  
  def create_reference
    ef = params[:exchange_reference]
    account_2 = Account.get_by_member_number(ef[:listing_number_2])

    if account_2 and account_2 != current_user.account and current_user.account.has_reference?(ef[:listing_number_2]) == false
      ef[:account_id_2] = account_2.id
      ef[:listing_number_1] = current_user.account.listings.first.listing_number
      ef[:account_id_1] = current_user.account.id

      ExchangeReference.request_reference(ef)
      flash.now[:success] = t('exchange_agrement.reference_requested')

      # Notify partner
      NotificationMailer.exchange_reference(account_2, ef[:listing_number_1]).deliver

    else
      flash.now[:alert] = t('exchange_agreement.could_not_send_request')
    end

    @exchange_references = current_user.account.get_references


    respond_to do |format|
      format.js
    end
  end
  
  
  def references
    @account = current_user.account
    @exchange_references = @account.get_references
    @exchange_approval_requests = @account.exchange_approval_requests?
    @new_reference = ExchangeReference.new
    
    respond_to do |format|
      format.html
    end
  end
  
  def update_reference
    @account = current_user.account
    er = ExchangeReference.find(params[:id])

    if er
      result = params[:value] == 'true' ? true : false
      er.update_attribute(params[:field], result)
    end

    @exchange_approval_requests = @account.exchange_approval_requests?
    
    flash.now[:success] = t('exchange_agreement.reference_updated')
    respond_to do |format|
      format.js
    end
  end
  
  
  def future
    
    account_id = current_user.account.id
    @exchange_agreements = ExchangeAgreement.by_owner(account_id).future
    active = []
    @exchange_agreements.each do |exchange_agreement|
      if Account.exists?(conditions: {_id: exchange_agreement.get_partner_account_id(account_id)})
        active.append(exchange_agreement)
      end
    end

    @exchange_agreements = active
    
    respond_to do |format|
      format.html
    end
  end

  def cancelled
    
    account_id = current_user.account.id
    @exchange_agreements = ExchangeAgreement.by_owner(account_id).cancelled
    active = []
    @exchange_agreements.each do |exchange_agreement|
      if Account.exists?(conditions: {_id: exchange_agreement.get_partner_account_id(account_id)})
        active.append(exchange_agreement)
      end
    end

    @exchange_agreements = active
    
    respond_to do |format|
      format.html
    end
  end
  
  
  def add_participant
    
    @rand_id = Random.rand(9999) + 9999
    
    respond_to do |format|
      format.js
    end
  end
  
  
  def remove_participant
    
    @participant_pos = params[:participant]
    
    respond_to do |format|
      format.js
    end
  end

  def show_and_sign
    exchange_agreement = ExchangeAgreement.where('agreements.owner' => current_user.account.id).find(params[:id])
    @member_agreement = exchange_agreement.agreements.where(owner: current_user.account.id).first
    
    partner_id = exchange_agreement.get_partner_account_id(current_user.account.id)
    @partner_agreement = exchange_agreement.agreements.where(owner: partner_id).first
    
    @member = current_user.account
    @partner = Account.find(partner_id)

    @exchange_agreement = exchange_agreement

    respond_to do |format|
      format.html { render :template => '/member/exchange_agreements/show.html.erb'}
    end
    
  end


  def documents
    
  end

private
  
  def exchange_agreement_params
    params.require(:agreement).permit(
      :show_mobile,
      :show_email,
      :start_date,
      :end_date,
      :has_car_insurance,
      :guests_allowed,
      :use_linen,
      :pets_allowed,
      participants_attributes: [],
      car_exchange_attributes: [:value],
      long_distance_calls_attributes: [:value],
      cleaning_attributes: [:value],
      key_exchange_attributes: [:value],
      pets_attributes: [:value],
      other_attributes: [:value]
    )
    
    #params.require(:agreement).permit(:show_mobile, :show_email, :start_date, :end_date, :participants, :car_exchange, :has_car_insurance, :long_distance_calls, :cleaning, :key_exchange, :pets, :other, :guests_allowed, :use_linen, :pets_allowed, :car_exchange_attributes, :long_distance_calls_attributes, :cleaning_attributes, :key_exchange_attributes, :pets_attributes, :other_attributes)
  end
  
end
