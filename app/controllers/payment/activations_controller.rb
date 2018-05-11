# encoding: UTF-8
class Payment::ActivationsController < ApplicationController
  layout "management"

  def show
    @countries = current_user.agent_profile.get_assigned_countries

    respond_to do |format|
      format.html
    end
  end

  def update
    marked_countries = params[:countries]
    @countries = current_user.agent_profile.get_assigned_countries

    @countries.each do |country|

      if marked_countries.include?(country.id.to_s)
        country.set_allow_direct_access(true)
      else
        country.set_allow_direct_access(false)
      end
    end

    respond_to do |format|
      format.html { redirect_to(automatic_activation_url) }
    end
  end

  ##
  # Lists all accounts that are waiting for activation
  def awaiting
    @accounts = current_user.agent_profile.get_awaiting_access_accounts

    respond_to do |format|
      format.html
    end
  end

  ##
  # Grants access and activates one account
  def grant
    begin
      @account = Account.has_permission(current_user).find(params[:account_id])
      @account.grant_access
    rescue => e
      NotificationMailer.oddity("Something with grant access went wrong. Error: #{e}").deliver
    end

    begin
      @user = User.find(@account.account_owner)
      subscription = @account.current_subscription()

      if subscription.renewal
        NotificationMailer.membership_renewal_activation(@user).deliver
      else
        NotificationMailer.membership_activation(@user).deliver
      end

    rescue => e
      NotificationMailer.oddity("Could not send grant access email. Error: #{e}").deliver
    end

    respond_to do |format|
      format.html { redirect_to(awaiting_account_activation_url) }
      format.js
    end
  end
end
