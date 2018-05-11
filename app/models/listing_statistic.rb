class ListingStatistic
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include ActiveModel::ForbiddenAttributesProtection
  belongs_to :listing, :class_name => "Listing"
  
  field :user_agent,          type: String, default: ''
  field :language,            type: String, default: ''
  field :user_type,           type: String, default: 'guest'
  field :country_short,       type: String, default: ''
  field :country_msgid,       type: String, default: ''
  field :ip_address,          type: String, default: ''
  field :count_date,          type: String, default: '' # Used for easer group by using MongoDB
  field :user_id,             type: BSON::ObjectId
  field :user_name,           type: String
  field :charset,             type: String
  field :account_id,          type: BSON::ObjectId
  field :account_number,      type: Integer
  field :listing_number,      type: String
  
  
  ##
  # Scopes data mapper style. Methods that returns criteria can be treated as chainable scopes as well.
  
end