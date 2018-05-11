class ExchangeAgreementActivity
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include ActiveModel::ForbiddenAttributesProtection
  
  embedded_in :exchange_agreement, :class_name => "ExchangeAgreement"
  
  field :activity,        type: String
  field :performed_by,    type: String
  field :user_id,         type: BSON::ObjectId
end
