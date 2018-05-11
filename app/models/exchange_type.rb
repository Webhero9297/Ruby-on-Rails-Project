# encoding: utf-8
class ExchangeType
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  field :msgid, type: String
  field :short, type: String
  field :selectable, type: Boolean, default: true

  scope :selectable, where(selectable: true)


  def self.filter_listing_types(listing_types)
    exchange_types = []
    self.selectable.each do |et|
      exchange_types.push(et.msgid)
    end
    listing_types = exchange_types & listing_types
    if listing_types.empty? or listing_types.include?('exchangetype.open_for_all_offers')
      return exchange_types
    end
    return listing_types
  end

end
