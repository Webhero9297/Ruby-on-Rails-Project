# encoding: utf-8
class PropertyDetail
  include Mongoid::Document
  
  field :msgid,     type: String
  field :short,     type: String
  field :selectable,      type: Boolean, default: true
  
  scope :selectable, where(selectable: true)
  
end
