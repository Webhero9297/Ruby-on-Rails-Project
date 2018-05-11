class EventLog
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  
  field :raw_data,        type: String, default: ''
  
end
