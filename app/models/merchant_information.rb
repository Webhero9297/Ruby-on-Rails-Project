class MerchantInformation
  include Mongoid::Document
  include Mongoid::Timestamps
  
  embedded_in :country, :class_name => 'Country'
  
  field :name,                  type: String
  field :address,               type: String
  field :postal_code,           type: String, default: nil
  field :postal_town,           type: String
  field :country_name,          type: String
  field :phone,                 type: String
  field :fax,                   type: String, default: nil
  field :email,                 type: String, default: nil
  field :organisation_number,   type: String, default: nil
  
  validates_presence_of :name, message: 'must be filled out'
  validates_presence_of :address, message: 'must be filled out'
  validates_presence_of :postal_town, message: 'must be filled out'
  validates_presence_of :country_name, message: 'must be filled out'
  validates_presence_of :phone, message: 'must be filled out'
  
end
