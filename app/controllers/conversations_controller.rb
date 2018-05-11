# encoding: UTF-8
class ConversationsController < ApplicationController
  filter_access_to :all
  layout "dashboard"
  before_filter :check_subscription
  before_filter lambda{ set_dashboard_scope('member') }, :only => [:index, :show]

  def index
    @conversations = Conversation.select_member_conversation_filter(params, current_user)
    @participants = Conversation.get_participants(@conversations)
    @user_time_zone = current_user.account.time_zone

    @unread_messages = @conversations.not_in(read_by: [current_user.account.id]).count

    @agent_unread_messages = Conversation.get_agent_conversations(params, current_user).not_in(read_by: [current_user.account.id])
    if current_user.is_agent
      @agent_unread_messages = @agent_unread_messages.where(started_by: current_user.account.id)
    end
    @agent_unread_messages = @agent_unread_messages.count

    respond_to do |format|
      format.html
      format.js
    end
  end

  # GET /conversations
  def member_agent_conversations_index
    @conversations = Conversation.select_agent_conversation_filter(params, current_user)

    if current_user.is_agent
      @conversations = @conversations.where(started_by: current_user.account.id)
    end

    @user_time_zone = current_user.account.time_zone

    @agent_unread_messages = @conversations.not_in(read_by: [current_user.account.id]).count
    @unread_messages = Conversation.get_member_conversations(params, current_user).not_in(read_by: [current_user.account.id]).count

    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
    account_id = current_user.account.id
    @conversation = Conversation.find(params[:id])
    @messages = @conversation.messages.order_by([[:created_at, :asc]])
    @conversation.mark_as_read(account_id)
    @return_url = conversations_url
    if @conversation.archived.include?(account_id)
      @return_url = archive_index_conversations_url
    end
    @conversation_partner = @conversation.get_conversation_partner(account_id)
    @account = Account.find(current_user.account.id)

    @unread_messages = Conversation.get_member_conversations(params, current_user).not_in(read_by: [current_user.account.id]).count

    @agent_unread_messages = Conversation.get_agent_conversations(params, current_user).not_in(read_by: [current_user.account.id])
    if current_user.is_agent
      @agent_unread_messages = @agent_unread_messages.where(started_by: current_user.account.id)
    end

    @agent_unread_messages = @agent_unread_messages.count
    @message_templates = @account.message_templates

    respond_to do |format|
      format.html
    end
  end

  def show_agent_conversation
    @conversation = Conversation.find(params[:id])
    @messages = @conversation.messages.order_by([[:created_at, :asc]])
    @conversation.mark_as_read(current_user.account.id)
    @return_url = conversations_url

    if @conversation.archived.include?(current_user.account.id)
      @return_url = archive_index_conversations_url
    end
    @conversation_partner = @conversation.get_conversation_partner(current_user.account.id)
    @account = current_user.account

    @unread_messages = Conversation.get_member_conversations(params, current_user).not_in(read_by: [current_user.account.id]).count

    @agent_unread_messages = Conversation.get_agent_conversations(params, current_user).not_in(read_by: [current_user.account.id])
    if current_user.is_agent
      @agent_unread_messages = @agent_unread_messages.where(started_by: current_user.account.id)
    end
    @agent_unread_messages = @agent_unread_messages.count

    respond_to do |format|
      format.html
    end
  end

  def new
    @member_account = Account.find(params[:account_id])
    @user_account = current_user.account
    subject = "Hello from #{current_user.name}"
    if @user_account.listings.first
      subject = "Exchange with #{@user_account.listings.first.listing_number}"
    end
    @conversation = Conversation.new(subject: subject)

    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @conversation = Conversation.create_new_conversation(params, current_user)
    respond_to do |format|
      if @conversation.save
        Conversation.send_push_notification_to_account_users(params[:member_account_id])
        format.html { redirect_to conversations_url, notice: t('alert.message_sent') }
        format.js
      else
        @conversation = Conversation.new
        @member_account = Account.find(params[:member_account_id])
        @user_account = current_user.account
        format.html { render action: "new" }
        format.js
      end
    end
  end

  def update
    @conversation = Conversation.find(params[:id])
    message = params[:message][:body]
    file_attachment = params[:file]
    mailgun_success = false
    valid = false
    if not message.blank?
      begin
        @conversation.reply(message, current_user, file_attachment)
        valid = true
        mailgun_success = true
      rescue ModondoMailgun::MailgunError
        mailgun_success = false
      rescue Mongoid::Errors::Validations
        valid = false
      end

      if valid and mailgun_success
        begin
          receivers = @conversation.get_receivers(current_user.account_id)
          receivers.each do |receiver|
            Conversation.send_push_notification_to_account_users(receiver.id)
          end
        rescue Exception
        end
      end
    end

    redirect_url = conversation_path(@conversation)
    if agent_session?
      redirect_url = agent_conversation_path(@conversation)
    end

    respond_to do |format|
      if valid and mailgun_success
        flash[:success] = t('alert.message_sent')
        format.html { redirect_to redirect_url }
      elsif valid and not mailgun_success
        flash[:alert] = t('alert.conversation_updated_email_not_sent')
        format.html { redirect_to redirect_url }
      else
        flash[:alert] = t('alert.message_could_not_be_sent')
        @error_message = t('alert.message_can_not_be_blank')

        @messages = @conversation.messages.order_by([[:created_at, :asc]])
        @conversation.mark_as_read(current_user.account.id)
        @return_url = conversations_url
        if @conversation.archived.include?(current_user.account.id)
          @return_url = archive_index_conversations_url
        end
        @conversation_partner = @conversation.get_conversation_partner(current_user.account.id)
      @account = current_user.account
        format.html { render(action: 'show')}
      end
    end
  end

  def hide_past_listing
    @user = User.find(params[:listing_owner])
    @conversation = Conversation.find(params[:id])
    @user.account.listings.update(open_past_listing: false)

    if @conversation.request_response == 'not_interested'
      respond_to do |format|
        format.html { redirect_to @conversation, notice: t('alert.response_already_sent') }
      end
      return
    end

    sender = @user
    message = "Thank you for your inquiry. At this time we are either not seeking an exchange in your area or have already found one. In any case we appreciate your interest in exchanging with us."

    begin
      reply = @conversation.reply(message, sender)
      success = true
      @conversation.set_not_interested
    rescue ModondoMailgun::MailgunError
      success = false
    end
    respond_to do |format|
      if reply and success
        format.html { redirect_to @conversation, notice: t('alert.conversation_updated') }
      else
        format.html { redirect_to @conversation, alert: t('alert.conversation_updated_email_not_sent') }
      end
    end
  end

  def not_interested
    current_user.reset_authentication_token!
    @conversation = Conversation.find(params[:id])

    if @conversation.request_response == 'not_interested'
      respond_to do |format|
        format.html { redirect_to @conversation, notice: t('alert.response_already_sent') }
      end
      return
    end

    sender = current_user
    if params[:listing_owner]
      user = User.find(params[:listing_owner])
      if user
        sender = user
      end
    end

    message = "Thank you for your inquiry. At this time we are either not seeking an exchange in your area or have already found one. In any case we appreciate your interest in exchanging with us."

    begin
      reply = @conversation.reply(message, sender)
      success = true
      @conversation.set_not_interested
    rescue ModondoMailgun::MailgunError
      success = false
    end
    respond_to do |format|
      if reply and success
        format.html { redirect_to @conversation, notice: t('alert.conversation_updated') }
      else
        format.html { redirect_to @conversation, alert: t('alert.conversation_updated_email_not_sent') }
      end
    end
  end

  def not_interested_no_user
    @user = User.find(params[:listing_owner])
    @conversation = Conversation.find(params[:id])

    if @conversation.request_response == 'not_interested'
      respond_to do |format|
        format.html { redirect_to @conversation, notice: t('alert.response_already_sent') }
      end
      return
    end

    sender = @user
    message = "Thank you for your inquiry. At this time we are either not seeking an exchange in your area or have already found one. In any case we appreciate your interest in exchanging with us."

    begin
      reply = @conversation.reply(message, sender)
      success = true
      @conversation.set_not_interested
    rescue ModondoMailgun::MailgunError
      success = false
    end
    respond_to do |format|
      if reply and success
        format.html { redirect_to @conversation, notice: t('alert.conversation_updated') }
      else
        format.html { redirect_to @conversation, alert: t('alert.conversation_updated_email_not_sent') }
      end
    end
  end

  def maybe_interested
    current_user.reset_authentication_token!
    @conversation = Conversation.find(params[:id])

    if @conversation.request_response == 'maybe-interested'
      respond_to do |format|
        format.html { redirect_to @conversation, notice: t('alert.response_already_sent') }
      end
      return
    end

    sender = current_user
    if params[:listing_owner]
      user = User.find(params[:listing_owner])
      if user
        sender = user
      end
    end

    message = "Your offer is interesting, but I am not sure yet."
    message = "I found your offer interesting, but I am not sure yet and I do not have a paid subscription at this time. As soon as I activate my account we will be able to get in touch." if current_user.account.listings.first.open_past_listing

    begin
      reply = @conversation.reply(message, sender)
      success = true
      @conversation.set_maybe_interested
    rescue ModondoMailgun::MailgunError
      success = false
    end

    date = "2018-02-01".to_date
    today = Date.today

    respond_to do |format|
      if current_user.account.listings.first.open_past_listing && today < date
        format.html { redirect_to special_renewal_subscriptions_path, notice: t('alert.conversation_updated') }
      elsif current_user.account.listings.first.open_past_listing
        format.html { redirect_to price_plans_path, notice: t('alert.conversation_updated') }
      elsif reply && success
        format.html { redirect_to @conversation, notice: t('alert.conversation_updated') }
      else
        format.html { redirect_to @conversation, alert: t('alert.conversation_updated_email_not_sent') }
      end
    end
  end

  def maybe_interested_no_user
    @user = User.find(params[:listing_owner])
    @conversation = Conversation.find(params[:id])

    if @conversation.request_response == 'maybe-interested'
      respond_to do |format|
        format.html { redirect_to @conversation, notice: t('alert.response_already_sent') }
      end
      return
    end

    sender = @user

    message = "Your offer is interesting, but I am not sure yet."
    message = "I found your offer interesting, but I am not sure yet and I do not have a paid subscription at this time. As soon as I activate my account we will be able to get in touch." if @user.account.listings.first.open_past_listing

    begin
      reply = @conversation.reply(message, sender)
      success = true
      @conversation.set_maybe_interested
    rescue ModondoMailgun::MailgunError
      success = false
    end
    respond_to do |format|
      if @user.account.listings.first.open_past_listing
        format.html { redirect_to special_renewal_subscriptions_path, notice: t('alert.conversation_updated') }
      elsif reply && success
        format.html { redirect_to @conversation, notice: t('alert.conversation_updated') }
      else
        format.html { redirect_to @conversation, alert: t('alert.conversation_updated_email_not_sent') }
      end
    end
  end

  def lets_talk
    current_user.reset_authentication_token!
    @conversation = Conversation.find(params[:id])

    if @conversation.request_response == 'interested'
      respond_to do |format|
        format.html { redirect_to @conversation, notice: t('alert.response_already_sent') }
      end
      return
    end

    sender = current_user
    if params[:listing_owner]
      user = User.find(params[:listing_owner])
      if user
        sender = user
      end
    end

    message = "I accept your offer, let's discuss the details"
    message = "I found your offer very interesting, but I do not have a paid subscription at this time. As soon as I activate my account we will be able to get in touch." if current_user.account.listings.first.open_past_listing

    begin
      reply = @conversation.reply(message, sender)
      success = true
      @conversation.set_interested
    rescue ModondoMailgun::MailgunError
      success = false
    end

    date = "2018-02-01".to_date
    today = Date.today

    respond_to do |format|
      if current_user.account.listings.first.open_past_listing && today < date
        format.html { redirect_to special_renewal_subscriptions_path, notice: t('alert.conversation_updated') }
      elsif current_user.account.listings.first.open_past_listing
        format.html { redirect_to price_plans_path, notice: t('alert.conversation_updated') }
      elsif reply and success
        format.html { redirect_to @conversation, notice: t('alert.conversation_updated') }
      else
        format.html { redirect_to @conversation, alert: t('alert.conversation_updated_email_not_sent') }
      end
    end
  end

  def lets_talk_no_user
    @user = User.find(params[:listing_owner])
    @conversation = Conversation.find(params[:id])

    if @conversation.request_response == 'interested'
      respond_to do |format|
        format.html { redirect_to @conversation, notice: t('alert.response_already_sent') }
      end
      return
    end

    sender = @user
    message = "I accept your offer, let's discuss the details"
    message = "I found your offer very interesting, but I do not have a paid subscription at this time. As soon as I activate my account we will be able to get in touch." if @user.account.listings.first.open_past_listing

    begin
      reply = @conversation.reply(message, sender)
      success = true
      @conversation.set_interested
    rescue ModondoMailgun::MailgunError
      success = false
    end

    respond_to do |format|
      if @user.account.listings.first.open_past_listing
        format.html { redirect_to special_renewal_subscriptions_path, notice: t('alert.conversation_updated') }
      elsif reply and success
        format.html { redirect_to @conversation, notice: t('alert.conversation_updated') }
      else
        format.html { redirect_to @conversation, alert: t('alert.conversation_updated_email_not_sent') }
      end
    end
  end

  def archive
    @conversation = Conversation.find(params[:id])
    @conversation.mark_as_archived(current_user.account.id)
    @conversation.mark_as_read(current_user.account.id)

    respond_to do |format|
      format.html { redirect_to conversations_url }
    end
  end

  def archive_index
    # If the current_user is on the agent dashboard
    if agent_session?
      @conversations = Conversation.select_agent_conversation_filter(params, current_user, archive=true)
    end

    # If the current_user is on the member dashboard
    if member_session?
      @conversations = Conversation.select_member_conversation_filter(params, current_user, archive=true)
    end

    @participants = Conversation.get_participants(@conversations)
    @user_time_zone = current_user.account.time_zone

    @unread_messages = Conversation.select_member_conversation_filter(params, current_user).not_in(read_by: [current_user.account.id]).count

    @agent_unread_messages = Conversation.get_agent_conversations(params, current_user).not_in(read_by: [current_user.account.id])
    if current_user.is_agent
      @agent_unread_messages = @agent_unread_messages.where(started_by: current_user.account.id)
    end
    @agent_unread_messages = @agent_unread_messages.count

    # returns an empty relation of conversations
    #
    # FIXME: this is a hack, we need to understand the business logic
    # and find a better way to do it
    @conversations = @conversations || Conversation.where(_id: "empty relation")

    respond_to do |format|
      format.html
      format.js
    end
  end

  def new_multi
    if not params[:favorites].nil?
      @conversation = Conversation.new
      @member_accounts = Account.find(params[:favorites])
      @user_account = current_user.account
    end

    respond_to do |format|
      if params[:favorites].nil?
        format.html { redirect_to(list_favorites_path, notice: t('favorites.no_selected')) }
      else
        format.html
      end
    end
  end

  def create_multi
    @body = params[:message][:body]
    @conversation = Conversation.create_multiple_conversations(params, current_user)
    respond_to do |format|
      if @conversation.valid?
        format.html { redirect_to conversations_url, notice: t('alert.message_sent') }
      else
        @member_accounts = Account.find(params[:member_accounts])
        @user_account = current_user.account
        format.html { render action: "new_multi" }
      end
    end
  end

  def destroy
    @conversation = Conversation.find(params[:id])
    @conversation.set_as_deleted(current_user.account.id)
    @conversation.mark_as_read(current_user.account.id)
    #@conversation.remove_conversation

    respond_to do |format|
      format.html { redirect_to conversations_url }
    end
  end

  def set_multiple_as_archived
    if params[:conversation] == nil
      render(nothing: true)
      return
    end

    # If the current_user is on the agent dashboard
    if agent_session?
      @conversations = Conversation.select_agent_conversation_filter(params, current_user)
    end

    # If the current_user is on the member dashboard
    if member_session?
      @conversations = Conversation.select_member_conversation_filter(params, current_user)
    end

    @participants = Conversation.get_participants(@conversations)
    @user_time_zone = current_user.account.time_zone

    @archived_conversations = Conversation.find(params[:conversation])
    @archived_conversations.each do |conversation|
      conversation.mark_as_archived(current_user.account.id)
      conversation.mark_as_read(current_user.account.id)
    end

    respond_to do |format|
      format.js
    end
  end

  def set_multiple_as_deleted
    if params[:conversation] == nil
      render(nothing: true)
      return
    end

    # If the current_user is on the agent dashboard
    if agent_session?
      @conversations = Conversation.select_agent_conversation_filter(params, current_user, archive=true)
    end

    # If the current_user is on the member dashboard
    if member_session?
      @conversations = Conversation.select_member_conversation_filter(params, current_user, archive=true)
    end

    @participants = Conversation.get_participants(@conversations)
    @user_time_zone = current_user.account.time_zone

    @deleted_conversations = Conversation.find(params[:conversation])
    @deleted_conversations.each do |conversation|
      conversation.set_as_deleted(current_user.account.id)
      conversation.mark_as_read(current_user.account.id)
    end

    respond_to do |format|
      format.js
    end
  end
end
