# encoding: UTF-8
class ExchangeRequestsController < ApplicationController
  
  filter_access_to :all
  layout "dashboard"
  before_filter :check_subscription
  
  def new
    @member_account = Account.find(params[:account_id])
    @member_listing = Listing.find(params[:listing_id])
    @user_account = current_user.account
    @conversation = Conversation.new(subject: "Wish to exchange with #{@member_listing.listing_number}")
    @return_url = listing_url(@member_listing)
    @return_url = request.referer unless request.referer.blank?

    session[:return_uri] = @return_url
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  
  def create
    @member_listing = Listing.find(params[:member_listing_id])
    @listing = @member_listing
    @conversation = Conversation.create_new_exchange_request(params, current_user)
    @body = params[:message][:body]
    respond_to do |format|
      if @conversation.valid?
        @member_account = Account.find(params[:member_account_id])
        @member_account.users.each do |user|
          user.ensure_authentication_token!
        end

        return_url = listing_url(params[:member_listing_id])
        uri = session[:return_uri]
        session[:return_uri] = nil
        if not uri.blank?
          return_url = uri
        end

        format.html { redirect_to return_url, notice: t('alert.exchange_request_sent') }
        format.js
      else
        
        @member_account = Account.find(params[:member_account_id])
        @user_account = current_user.account
        format.html { render :new }
        format.js { render(template: 'exchange_requests/not_valid.js.erb') }
      end
    end
  end


  def cancel

    @listing = Listing.find(params[:listing_id])
    respond_to do |format|
      format.js
    end
  end

end
