class MessageTemplate
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection

  embedded_in :account, :class_name => "Account"

  validates :name, :length => {
    :minimum => 2,
    :maximum => 200,
    :message => 'message_template.error.you_must_name_your_template'
  }

  field :name,     type: String, default: nil
  field :subject,  type: String, default: ''
  field :body,     type: String, default: ''
  field :category, type: String, default: 'send'
end
