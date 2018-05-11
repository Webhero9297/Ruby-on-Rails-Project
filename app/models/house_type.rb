# encoding: utf-8
class HouseType
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  field :msgid,           type: String
  field :short,           type: String
  field :selectable,      type: Boolean, default: true
  
  scope :selectable, where(selectable: true)
end
