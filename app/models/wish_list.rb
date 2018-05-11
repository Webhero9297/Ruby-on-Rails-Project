class WishList
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  
  embedded_in :profile, :class_name => "Profile"
  
  field :destination,         type: String
  field :country_code,        type: String
  field :location,            type: Array, default: []#, spacial: true
  field :ne_lat,              type: Float, default: 0.0
  field :ne_lng,              type: Float, default: 0.0
  field :sw_lat,              type: Float, default: 0.0
  field :sw_lng,              type: Float, default: 0.0
  
  index [[ :location, Mongo::GEO2D ]], min: -180, max: 180
  
end
