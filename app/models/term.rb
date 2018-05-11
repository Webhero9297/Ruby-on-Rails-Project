class Term
  include Mongoid::Document
  include Mongoid::Timestamps::Updated
  include ActiveModel::ForbiddenAttributesProtection
  
  embedded_in :agreement, :class_name => "Agreement"
  
  field :value,                 type: String, default: ''
  field :accepted_by_partner,   type: Boolean, default: nil
  field :reason,                type: String, default: ''
  
end
