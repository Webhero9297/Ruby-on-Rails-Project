class Sorry
  include Mongoid::Document
  store_in :sorry
  field :account_id,     	type: BSON::ObjectId
  field :sent,			  	type: Boolean, default: false
  field :country_code,		type: String, default: nil
  
end
