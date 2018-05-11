class Conversation
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  embeds_many :messages, :class_name => "Message"

  field :participants,        type: Array, default: []
  field :deleted,             type: Array, default: []
  field :archived,            type: Array, default: []
  field :read_by,             type: Array, default: []
  field :started_by,          type: BSON::ObjectId #AccountID
  field :subject,             type: String
  field :notification,        type: Boolean, default: false
  field :kind,                type: String, default: 'member_to_member'

  field :request_reminders,   type: Integer
  field :last_reminder_sent,  type: DateTime
  field :request_response,    type: String, default: nil
  field :listings,            type: Hash, default: {} # {account_id: listing_number}*N - the key is the account number as a string and references the listing in context

  validates_presence_of :subject
  accepts_nested_attributes_for :messages, :allow_destroy => true

  index(
    [
      [:participants, 1],
      [:archived, 1],
      [:read_by, 1]
    ]
  )
  scope :not_deleted, ->(account_id) { not_in(deleted: [account_id]) }
  scope :exchange_request_with_no_reply_since, -> (since = 7.days){
    where(kind: "member_to_member")
      .where(:created_at.gte => DateTime.current - 2.months)
      .where(:request_response => nil)
      .where(:messages.size => 1)
      .where(:"messages.kind" => "exchange_request")
      .any_of(
        {:last_reminder_sent => nil},
        {:last_reminder_sent.lte => DateTime.current - since}
      )
  }

  def self.find_member_conversations(params, user, archived=false)
    sort_order = self.determine_sort_order(params[:d])
    threads_per_page = 20
    member = Listing.find_by_listing_number(params[:q]).first

    if member.nil?
      return self.where(:id => -1).page(params[:page]).per(threads_per_page)
    end

    conversations = self.where(:kind => 'member_to_member').all_in(participants: [user.account.id, member.account_id])

    if archived
      conversations = conversations.in(archived: [user.account.id])
    else
      conversations = conversations.not_in(archived: [user.account.id])
    end

    if self.show_unread?(params[:f])
      conversations = conversations.not_in(read_by: [user.account.id])
    end

    conversations.not_deleted(user.account.id).where(:messages.exists => true).order_by([:updated_at, sort_order]).page(params[:page]).per(threads_per_page)
  end

  def self.get_member_conversations(params, user, archived=false)
    threads_per_page = 20
    sort_order = self.determine_sort_order(params[:d])

    conversations = self.where(:kind => 'member_to_member').where(participants: user.account.id)

    if archived
      conversations = conversations.in(archived: [user.account.id])
    else
      conversations = conversations.not_in(archived: [user.account.id])
    end

    if self.show_unread?(params[:f])
      conversations = conversations.not_in(read_by: [user.account.id])
    end

    conversations.not_deleted(user.account.id).where(:messages.exists => true).order_by([:updated_at, sort_order]).page(params[:page]).per(threads_per_page)
  end

  def self.get_number_of_unread_conversations(user, kind=%w(member_to_member agent_to_member member_to_agent))
    account_id = user.account.id
    self.where(:kind.in => kind).where(:participants.in => [account_id]).not_in(archived: [account_id]).not_in(read_by: [account_id]).not_in(deleted: [account_id]).where(:messages.exists => true).count
  end

  def self.find_agent_conversations(params, user, archived=false)
    sort_order = self.determine_sort_order(params[:d])
    threads_per_page = 20
    member = Listing.find_by_listing_number(params[:q]).first

    if member.nil?
      return self.where(:id => -1).page(params[:page]).per(threads_per_page)
    end

    conversations = self.where(:kind.in => ['member_to_agent', 'agent_to_member']).all_in(participants: [user.account.id, member.account_id])

    if archived
      conversations = conversations.in(archived: [user.account.id])
    else
      conversations = conversations.not_in(archived: [user.account.id])
    end

    if self.show_unread?(params[:f])
      conversations = conversations.not_in(read_by: [user.account.id])
    end

    conversations.not_deleted(user.account.id).where(:messages.exists => true).order_by([:updated_at, sort_order]).page(params[:page]).per(threads_per_page)
  end

  def self.get_agent_conversations(params, user, archived=false)
    threads_per_page = 20
    sort_order = self.determine_sort_order(params[:d])

    conversations = self.where(:kind.in => ['member_to_agent', 'agent_to_member']).where(participants: user.account.id)

    if archived
      conversations = conversations.in(archived: [user.account.id])
    else
      conversations = conversations.not_in(archived: [user.account.id])
    end

    if self.show_unread?(params[:f])
      conversations = conversations.not_in(read_by: [user.account.id])
    end

    conversations = conversations.not_deleted(user.account.id).where(:messages.exists => true).order_by([:updated_at, sort_order]).page(params[:page]).per(threads_per_page)
    conversations
  end

  def self.get_last_interaction(user, listing)
    self.interactions(user, listing).limit(1).first
  end

  def self.determine_sort_order(sorting)
    if sorting.blank? or sorting == 'last'
      return :desc
    end

    :asc
  end

  def self.show_unread?(filter)
    if filter.blank? or filter == 'all'
      return false
    end

    true
  end

  ##
  # Used for agent contact messages.
  # Participants is an array of account ids.
  # TODO should be merged into create_new_conversation
  def self.create_contact_message(params, participants, user)
    member_id = user.name
    if user.account.has_listing?
      listing_number = user.account.listings.first.listing_number
      member_id = listing_number
    end

    subject = "[#{member_id} | #{I18n.t(user.account.get_country.msgid)}] #{params[:conversation][:subject]}"

    conversation = self.new(
      subject: subject,
      participants: participants,
      read_by: [user.account.id],
      started_by: user.account.id,
      kind: params[:kind]
    )

    if not conversation.valid?
      return conversation
    end

    conversation.messages.create(
      body: params[:message][:body],
      sent_by_user: user.name,
      sent_by_account: user.account.id
    )

    conversation
  end

  def self.create_new_conversation(params, user)
    allowed_kinds = ['member_to_member', 'agent_to_member', 'member_to_agent']
    kind = params[:conversation][:kind]
    file = params[:file]

    if not allowed_kinds.include?(kind)
      kind = 'member_to_member'
    end

    conversation = self.new(
      subject: params[:conversation][:subject],
      participants: [user.account.id, BSON::ObjectId(params[:member_account_id])],
      read_by: [user.account.id],
      started_by: user.account.id,
      kind: kind
    )

    if not conversation.valid?
      return conversation
    end

    message = conversation.messages.create(
      body: params[:message][:body],
      sent_by_user: user.name,
      sent_by_account: user.account.id
    )
    message.attachments.create(file: file) if file
    conversation
  end

  def self.create_new_exchange_request(params, user)
    conversation = self.new(
      subject: params[:conversation][:subject],
      participants: [user.account.id, BSON::ObjectId(params[:member_account_id])],
      read_by: [user.account.id],
      started_by: user.account.id,
      kind: 'member_to_member',
      request_reminders: 0,
      last_reminder_sent: Time.now.utc,
      request_response: nil,
      listings: {:"#{params[:member_account_id]}" => params[:member_listing_id]}
    )

    if not conversation.valid?
      return conversation
    end

    user.account.update_attributes(last_reminder_sent: Time.now.utc)

    message = conversation.messages.create(
      body: params[:message][:body],
      sent_by_user: user.name,
      sent_by_account: user.account.id,
      kind: 'exchange_request'
    )

    message.attachments.create(file: params[:file]) if params[:file]
    conversation
  end

  def self.create_multiple_conversations(subject, body_text, listing_ids, user)
    member_listings = Listing.find(listing_ids)

    conversation = nil
    member_listings.each do |listing|
      conversation = self.create(
        subject: subject,
        participants: [user.account.id, listing.account_id],
        read_by: [user.account.id],
        started_by: user.account.id
      )

      if not conversation.valid?
        return conversation
      end

      conversation.messages.create(
        body: body_text,
        sent_by_user: user.name,
        sent_by_account: user.account.id
      )

    end

    conversation
  end

  # Used for sending system conversations to users.
  def self.create_multiple_notifications(account_ids, message)
    system_user = User.first(conditions: { roles: 'system' })

    account_ids.each do |account_id|
      conversation = self.create!(
        subject: message[:subject],
        participants: [system_user.account.id, account_id],
        read_by: [system_user.account.id],
        started_by: system_user.account.id,
        notification: true
      )

      conversation.messages.create(
        body: message[:body],
        sent_by_user: system_user.name,
        sent_by_account: [system_user.account.id]
      )
    end

    true
  end

  def self.interactions(user, listing)
    return unless user

    all_in(participants: [user.account.id, listing.account_id]).
      where(:messages.exists => true).
      order_by([:updated_at, :desc])
  end

  def reply(text, user, attachment_file=nil)
    if not self.archived.empty?
      self.set(:archived, [])
    end

    self.read_by = [user.account.id]
    self.save

    message = self.messages.create(
      sent_by_user: user.name,
      body: text,
      sent_by_account: user.account.id
    )

    if not attachment_file.nil?
      message.attachments.create(file: attachment_file)
    end

    message
  end

  def mark_as_read(account_id)
    self.add_to_set(:read_by, account_id)
  end

  def mark_as_archived(account_id)
    self.push(:archived, account_id)
  end

  def set_as_deleted(account_id)
    self.push(:deleted, account_id)
  end

  def remove_conversation
    participants = self.participants.count
    deleted = self.deleted.count

    if participants == deleted
      self.destroy
    end
  end

  def self.get_participants(chats)
    conversations = chats || []
    participants  = []

    conversations.each do |conversation|
      participants.concat(conversation.participants)
    end

    participants = participants.uniq
    accounts = Account.find(participants)

    accounts
  end

  def get_conversation_partner(current_account_id)
    begin
      parties = self.participants
      parties.delete(current_account_id)

      Account.all_accounts.find(parties.first)
    rescue
      nil
    end
  end

  def get_receivers(except)
    parts = self.participants.uniq
    parts.delete(except)
    accounts = Account.find(parts)
    accounts
  end

  def set_not_interested
    self.set(:request_response, 'not_interested')
  end

  def set_interested
    self.set(:request_response, 'interested')
  end
  def set_maybe_interested
    self.set(:request_response, 'maybe_interested')
  end

  def self.get_status_object(mailgun_id)
    begin
      return self.where(:"messages.statuses.mailgun_id" => mailgun_id).first.messages.where(:"statuses.mailgun_id" => mailgun_id).first.statuses.where(mailgun_id: mailgun_id).first
    rescue
      return false
    end
  end

  def self.get_by_mailgun_id(mailgun_id)
    where(:"messages.statuses.mailgun_id" => mailgun_id).first
  end

  ##
  # Triggers the push message for connected devices to the users of the account
  def self.send_push_notification_to_account_users(account_id)
    users = User.where(account_id: account_id)

    users.each do |user|
      if user.device_token
        badge_number = 1
        Conversation.push_notification(user.device_token, badge_number, user.device_type)
      end
    end
  end

  # Sends the message to Parse
  def self.push_notification(device_token, nr_of_unread_messages, device_type)

    api_url = "https://api.parse.com/1/push"
    headers = {
        :'X-Parse-Application-Id' => Rails.application.config.parse_application_id,
        :'X-Parse-REST-API-Key' => Rails.application.config.parse_rest_api_key,
        :'Content-Type' => 'application/json'
    }
    body = {}

    # IOS specific settings
    if device_type == 'ios'
      body = {
          where: {
              deviceType: 'ios',
              deviceToken: device_token
          },
          data: {
              badge: nr_of_unread_messages,
              alert: "New message from Intervac!"
          }
      }
    end

    # Android specific settings
    if device_type == 'android'
      body = {
          where: {
              deviceType: 'android',
              installationId: device_token
          },
          data: {
              alert: "New message from Intervac!"
          }
      }
    end

    RestClient.post(api_url, body.to_json, headers)
  end

  ##
  # Filters the conversation based on the query params if the filter is a search or not for agent messages
  def self.select_agent_conversation_filter(params, current_user, archive=false)
    if params[:q].blank?
      return @conversations = Conversation.get_agent_conversations(params, current_user, archive)
    end

    @conversations = Conversation.find_agent_conversations(params, current_user, archive)
  end

  ##
  # Filters the conversation based on the query params if the filter is a search or not for member messages
  def self.select_member_conversation_filter(params, current_user, archive=false)
    if params[:q].blank?
      return @conversations = Conversation.get_member_conversations(params, current_user, archive)
    end

    @conversations = Conversation.find_member_conversations(params, current_user, archive)
  end
end
