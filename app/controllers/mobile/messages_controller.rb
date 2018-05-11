# encoding: UTF-8
class Mobile::MessagesController < ApplicationController

  filter_access_to :all
  layout 'mobile'
  before_filter :check_subscription
  before_filter :set_as_mobile

  def index
    @screen_title = "Messages"
    @conversations = Conversation.all_in(participants: [current_user.account.id]).not_in(archived: [current_user.account.id]).order_by([:updated_at, :desc]).to_a
    @participants = Conversation.get_participants(@conversations)

    respond_to do |format|
      format.html
    end
  end


  def show
    @screen_title = "Messages"
    @conversation = Conversation.find(params[:id])
    @messages = @conversation.messages.order_by([[:created_at, :asc]])
    @conversation.mark_as_read(current_user.account.id)
    @return_url = conversations_url
    if @conversation.archived.include?(current_user.account.id)
      @return_url = archive_index_conversations_url
    end

    respond_to do |format|
      format.html
    end
  end


  def new
    @screen_title = "Messages"
    @member_listing = Listing.find(params[:listing_id])
    @member_account = @member_listing.account
    @user_account = current_user.account
    @conversation = Conversation.new(subject: "Exchange with #{@user_account.listings.first.listing_number}")
    
    respond_to do |format|
      format.html
    end
  end


  def unread_messages
    begin
      messages_waiting = Conversation.where(participants: current_user.account.id).not_in(archived: [current_user.account.id]).not_in(read_by: [current_user.account.id]).count
    rescue Exception => e
      messages_waiting = 0
    end

    respond_to do |format|
      format.json { render :json => messages_waiting }
    end
  end

  def create
    @conversation = Conversation.create_new_conversation(params, current_user)
    
    respond_to do |format|
      if @conversation.save
        Conversation.send_push_notification_to_account_users(params[:member_account_id])
        format.html { redirect_to mobile_listing_path(params[:member_listing_id]), notice: t('alert.message_sent') }
      else
        @conversation = Conversation.new
        @member_account = Account.find(params[:member_account_id])
        @member_listing = Listing.find(params[:member_listing_id])
        @user_account = current_user.account
        format.html { render action: "new" }
      end
    end
  end


  def update
    @conversation = Conversation.find(params[:id])
    message = params[:message][:body]
    file_attachment = params[:file]
    
    begin
      reply = @conversation.reply(message, current_user, file_attachment)
      success = true
    rescue ModondoMailgun::MailgunError => e
      success = false
    end

    if reply and success
      begin
        receivers = @conversation.get_receivers(current_user.account_id)
        receivers.each do |receiver|
          Conversation.send_push_notification_to_account_users(receiver.id)
        end
      rescue Exception => e
        
      end
    end

    respond_to do |format|
      if reply and success
        flash[:success] = t('alert.message_sent')
      else
        flash[:alert] = t('alert.conversation_updated_email_not_sent')
      end
      format.html { redirect_to mobile_messages_path }
    end
  end

end
