class ExchangePartner
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  
  attr_accessor :listing_number
  
  validates_presence_of :listing_number
  validates_length_of :listing_number, allow_blank: false, minimum: 5, maximum: 10
  
  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end
  
  def persisted?
    false
  end
end
