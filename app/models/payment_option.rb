class PaymentOption
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  
  embedded_in :price_plan, :class_name => 'PricePlan'
  
  field :billing_cycle,   type: Integer
  field :discount,        type: Integer
  field :description,     type: String
  field :default,         type: Boolean, default: false
  
end
