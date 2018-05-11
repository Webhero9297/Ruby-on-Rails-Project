class ValidProfile
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  
  attr_accessor :name, :address, :postal_town, :postal_code, :county, :fax, :skype, :website, :telephone, :mobile, :email, :spoken_languages, :adults
  
  validates_presence_of :name, :address, :postal_town, :email
  validates_format_of :email, :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i
  validate :is_empty
  
  validate :one_of
  
  FINISHED_COUNT = 7
  
  def one_of
    if telephone.blank? and mobile.blank?
      errors.add(:phone, I18n.t('error.missing_phone_number')) #Add at  least one phone number
    end
  end
  
  def is_empty
    if spoken_languages.blank? or spoken_languages.empty?
      errors.add(:spoken_languages, I18n.t('error.missing_spoken_language')) #Add at least one spoken language
    end
  end
  
  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end
  
  def persisted?
    false
  end
  
  # Return progress fro how complete the account profile is
  def progress
    self.valid?
    errors_count = self.errors.count
    progress = (ValidProfile::FINISHED_COUNT - errors_count).to_f / ValidProfile::FINISHED_COUNT.to_f * 100
    return progress.to_i
  end
  
  
  ##
  # Sets all the parameters that needs to be validated before a listing can go live.
  def self.get_validation_params(account)
    
    params = {
      name: account.contact.name,
      address: account.contact.address,
      postal_town: account.contact.postal_town,
      telephone: account.contact.telephone,
      mobile: account.contact.mobile,
      email: account.contact.email,
      spoken_languages: account.profile.spoken_languages
    }
    
    return params
  end

  
  def is_missing_field(field)
    
    if self.errors.messages.has_key?(field)
      return true
    end
    
    return false
  end
end
