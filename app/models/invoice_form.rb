class InvoiceForm
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  
  attr_accessor :fullname, :street, :city, :postal_code, :country, :phone
  
  validates_presence_of :fullname, :message => 'must be first name last name'
  validates_presence_of :street, :message => 'must be a valid address'
  validates_presence_of :city, :message => 'must be a valid city'
  # validates_presence_of :postal_code, :message => 'must be a valid postal code' # will have to see if there is some better way to validate an internationl address
  validates_presence_of :country, :message => 'must be a country'
  validates_presence_of :phone, :message => 'must be a phone number'
  
  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end
  
  def persisted?
    false
  end
end
