# encoding: UTF-8
class MemberMessagesController < ApplicationController
  
  filter_access_to :all
  layout "dashboard"
  before_filter :check_subscription
  
  def new
    @member_account = Account.find(params[:account_id])
    @member_listing = Listing.find(params[:listing_id])
    @user_account = current_user.account
    @conversation = Conversation.new

    respond_to do |format|
      format.js
    end
  end
  
  
  def create

    @member_account = Account.find(params[:member_account_id])
    @member_listing = Listing.find(params[:member_listing_id])
    @listing = @member_listing
    @body = params[:message][:body]
    @conversation = Conversation.create_new_conversation(params, current_user)

    respond_to do |format|
      if @conversation.save
        @member_account.users.each do |user|
          user.ensure_authentication_token!
        end
        format.js
      else
        @user_account = current_user.account
        format.js { render(template: 'member_messages/not_valid.js.erb') }
      end
    end
  end


  def cancel
    @listing = Listing.find(params[:listing_id])
    respond_to do |format|
      format.js
    end
  end


  def multi_message

    @subject = params[:subject]
    @body_text = params[:body_text]
    @listing_ids = params[:listings]

    if @listing_ids.blank?
      @conversation = Conversation.new
      render(template: 'member_messages/missing_recipients.js.erb')
      return
    end

    @recipients = Listing.find(@listing_ids)
    @conversation = Conversation.create_multiple_conversations(@subject, @body_text, @listing_ids, current_user)

    respond_to do |format|
      if @conversation.valid?
        format.js
      else
        format.js {render(template: 'member_messages/not_valid_multi_message.js.erb')}
      end
    end
  end


  def add_recipient_to_multi_list
    @listing = Listing.find(params[:listing_id])
    respond_to do |format|
      format.js
    end
  end


  def remove_recipient_from_multi_list
    @listing = Listing.find(params[:listing_id])
    respond_to do |format|
      format.js
    end
  end
  
end