class MessageStatus
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection

  embedded_in :message, :class_name => 'Message'

  field :mailgun_id,        type: String
  field :account_id,        type: Integer
  field :delivered,         type: Boolean, default: false
  field :read,              type: Boolean, default: false
  field :failed,            type: Boolean, default: false

  def set_delivered
    self.set(:delivered, true)
  end

  def set_read
    self.set(:read, true)
  end

  def set_failed
    self.set(:failed, true)
  end

  def self.is_read_by(account_id)
    status = self.where(account_id: account_id).first
    if status and status.read
      return true
    end
    return false
  end
end
