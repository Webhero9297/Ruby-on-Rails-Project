class OrderTransaction
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  
  embedded_in :order, :class_name => "Order"
  
  field :action,          type: String, default: nil
  field :amount,          type: Integer, default: 0
  field :success,         type: Boolean, default: false
  field :authorization,   type: String, default: nil
  field :message,         type: String, default: nil
  field :params,          type: Hash, default: nil
  
  
  def response=(response)
    self.success       = response.success?
    self.authorization = response.authorization
    self.message       = response.message
    self.params        = response.params
  
  rescue ActiveMerchant::ActiveMerchantError => e
    self.success       = false
    self.authorization = nil
    self.message       = e.message
    self.params        = {}
  end
end
