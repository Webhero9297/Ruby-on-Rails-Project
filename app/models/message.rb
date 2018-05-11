class Message
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  embedded_in :conversation, :class_name => 'Conversation'
  embeds_many :statuses, :class_name => "MessageStatus"
  embeds_many :attachments, :class_name => "Attachment"

  field :body,                    type: String
  field :sent_by_user,            type: String
  field :sent_by_account,         type: BSON::ObjectId
  field :kind,                    type: String, default: 'message'
  field :message_id,              type: String, default: nil

  validates_presence_of :body
  validates_length_of :body, allow_blank: false, maximum: 8096

  after_save :send_email

  def get_status_for_account(account)
    status = self.statuses.where(account_id: account.id).first
    return status
  end

  protected

  def send_email
    receiver_accounts = conversation.get_receivers(self.sent_by_account)
    for receiver_account in receiver_accounts

      if receiver_account.contact.email.nil?
        next
      end

      if (receiver_account.is_restricted) && conversation.kind == 'member_to_member'
        receiver_account.users.each do |user|
          result = NotificationMailer.trial_message_notification(self, user, self.sent_by_account).deliver
          if result
            self.statuses.create(
              mailgun_id: "<#{result.message_id}>",
              account_id: receiver_account.id,
              delivered: true
            )
          else
            # Something went wrong when sending e-mail
            self.statuses.create(
              failed: true,
              account_id: receiver_account.id
            )
          end
        end
        next
      end

      if self.conversation.kind == 'member_to_agent'
        result = ConversationMailer.contact_agent(receiver_account, self).deliver
      else
        result = ConversationMailer.contact(receiver_account, self).deliver
      end

      if result
        self.statuses.create(
          mailgun_id: "<#{result.message_id}>",
          account_id: receiver_account.id,
          delivered: true
        )
        next
      end
      # Something went wrong when sending e-mail
      self.statuses.create(
        failed: true,
        account_id: receiver_account.id
      )
      raise ModondoMailgun::MailgunError.new("Mail could not be sent")
    end
  end
end
