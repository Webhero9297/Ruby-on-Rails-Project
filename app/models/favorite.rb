# encoding: utf-8
class Favorite
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection

  embedded_in :account, :class_name => 'Account'

  field :listing_id,  type: String
  field :note,        type: String
end
