# encoding: UTF-8
class Accounts::AccountsController < ApplicationController
  filter_access_to :all
  layout "dashboard"

  def index
    @accounts = accounts.order_by([:created_at, :desc]).page(params[:page]).per(20)

    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
    @account = accounts.find(params[:id])
    @account_owner = User.find(@account.account_owner)
    @subscription = @account.current_subscription
    @subscriptions = @account.subscriptions.order_by([[:expires_at, :desc]])
    @countries = Country.sorted_by_language
    @exchange_agreements = ExchangeAgreement.where(:parties.in => [@account.id]).order_by([[:created_at, :desc]])

    @account.listings.each do |listing|
      listing.set_account_data_on_listing
    end

    respond_to do |format|
      if @account.subscriptions.empty?
        format.html {render(template: 'accounts/accounts/show_uncomfirmed', layout: 'management')}
      else
        @account.manually_sync_data
        format.html {render(layout: 'management')}
      end
    end
  end

  def update
    @account = accounts.find(params[:id])
    @account.set_exchanges_made(params[:account][:exchanges_made])

    @message = "Number of exchanges made updated!"
    @type = "success"
    respond_to do |format|
      format.js
    end
  end

  def search
    for_user = session[:dashboard] == 'admin' ? nil : current_user
    @accounts = AccountsListing.find_member_by_params(params, for_user).page(params[:page]).per(20).all

    respond_to do |format|
      format.json
      format.js
    end
  end

  def filter
    @accounts = AccountsListing.filter_members_by_params(params).page(params[:page]).per(20).all

    respond_to do |format|
      format.html
      format.js
    end
  end

  ##
  # Landing page for terminating an account that specifically tells the user about the actions.
  def confirm_termination
    @account = accounts.find(params[:id])

    respond_to do |format|
      format.html {render(layout: 'management')}
    end
  end

  ##
  # Terminates an account.
  def terminate
    begin
      event = {event: 'Terminated account from admin', current_user: current_user.name, account_id: params[:id]}
      EventLog.create(event)
    rescue
    end

    Account.terminate_account(params[:id])

    respond_to do |format|
      format.html { redirect_to( action: 'termination_confirmed' )}
    end
  end

  ##
  #  Landing page after an account as been terminated.
  def termination_confirmed
    respond_to do |format|
      format.html {render(layout: 'management')}
    end
  end

  def set_joined_at
    @account = accounts.has_permission(current_user).find(params[:id])
    @account.set_joined_at(params[:account][:joined_at])

    flash[:notice] = 'Joined at date updated'
    respond_to do |format|
      format.js
    end
  end

  def set_as_ambassador
    @account = accounts.has_permission(current_user).find(params[:id])
    @account.get_owner.set_as_ambassador

    respond_to do |format|
      format.js
    end
  end

  def download
    countries = []
    if current_user.is_agent
      countries = current_user.agent_profile.get_assigned_countries_short_codes
    elsif current_user.is_admin
      countries = Country.get_shorts_as_array(false)
    end

    respond_to do |format|
      format.csv {send_data Account.as_csv(countries), :type => 'text/csv', :filename => 'accounts.csv', :disposition => 'attachment'}
    end
  end

  def transfer_account
    @account = accounts.find(params[:account_id])
    @countries = Country.sorted_by_language

    @account.transfer_to_country(params[:agent][:country])

    respond_to do |format|
      format.html {redirect_to(account_path(@account.id), notice: t('alert.account_has_been_transferred'))}
    end
  end

  def set_nr_of_exchanges
    @account = accounts.has_permission(current_user).find(params[:id])
    @account.set_exchanges_made(params[:exchanges_made])

    flash[:notice] = 'Number of exchanges updated'
    respond_to do |format|
      format.js
    end
  end

  def update_nr_of_allowed_listings
    @account = accounts.has_permission(current_user).find(params[:id])
    @account.nr_of_allowed_listings = params[:nr_of_allowed_listings]

    respond_to do |format|
      if @account.save
        flash[:notice] = 'Number of allowed listings updated'
      else
        flash[:notice] = 'Could not update allowed listings'
      end
      @account.reload
      format.js
    end
  end

  private

  def accounts
    Account.unscoped
  end
end
