class ProfileProgress
  include ActiveAttr::Model
  include ActiveAttr::MassAssignment
  include ActiveModel::MassAssignmentSecurity

  attribute :name
  attribute :address
  attribute :postal_town
  attribute :telephone
  attribute :mobile
  attribute :email
  attribute :spoken_languages
  attribute :wish_list_destinations
  attribute :lifestyle
  attribute :family
  attribute :occupations
  attribute :profile_images

  attr_accessor :name, :address, :postal_town, :telephone, :mobile, :email, :spoken_languages, :wish_list_destinations, :lifestyle, :family, :occupations, :profile_images

  validates_presence_of :name, :address, :postal_town, :email, :lifestyle, :family

  validates :telephone, :presence => {:unless => Proc.new { |a| a.mobile.present? }, :length => {:minimum => 2, :maximum => 20 }, :message => I18n.t('error.must_enter_either_telephone_or_mobile')}
  validates :mobile, :presence => {:unless => Proc.new { |a| a.telephone.present? }, :length => {:minimum => 2, :maximum => 20 }, :message => I18n.t('error.must_enter_either_telephone_or_mobile')}

  validate :check_for_spoken_languages
  validate :check_for_wish_list_destinations
  validate :check_for_occupations
  validate :check_for_profile_images

  FINISHED_COUNT = 12

  ##
  # Checks if the account has any profile images added
  def check_for_profile_images
    if profile_images.empty?
      errors.add(:profile_images, I18n.t('error.missing_profile_image'))
    end
  end

  ##
  # Checks to see if the account has any wish list destinations
  def check_for_wish_list_destinations
    if wish_list_destinations.empty?
      errors.add(:wish_list_destinations, I18n.t('error.missing_wish_list_destination'))
    end
  end

  ##
  # Checks to see how many adults that are added.
  def check_for_occupations
    if occupations.empty?
      errors.add(:occupations, I18n.t('error.missing_ocupation'))
    end
  end

  ##
  # Checks to see if there is at least on spoken language connected
  def check_for_spoken_languages
    if spoken_languages.blank? or spoken_languages.empty?
      errors.add(:spoken_languages, I18n.t('error.missing_spoken_language'))
    end
  end

  ##
  # Collectes and returns all validation params to messure the progress
  def self.get_progress_params(account)
    params = {
      name: account.contact.name,
      address: account.contact.address,
      postal_town: account.contact.postal_town,
      telephone: account.contact.telephone,
      mobile: account.contact.mobile,
      email: account.contact.email,
      spoken_languages: account.profile.spoken_languages,
      wish_list_destinations: account.profile.wish_list_destinations,
      lifestyle: account.profile.lifestyle.text,
      family: account.profile.presentation.text,
      occupations: account.profile.adults,
      profile_images: account.profile.profile_images
    }
    return params
  end

  ##
  # Returns the profile progress in a percentage integer
  def progress
    self.valid?
    errors_count = self.errors.count
    progress = (ProfileProgress::FINISHED_COUNT - errors_count).to_f / ProfileProgress::FINISHED_COUNT.to_f * 100
    return progress.to_i
  end

  ##
  # Helper method to check if a attribute passed validation or not.
  def is_missing(field)
    if self.errors.messages.has_key?(field)
      return true
    end
    return false
  end

  ##
  # Check to see of the account profile is complete
  def is_complete?
    self.valid?

    if self.errors.count == 0
      return true
    end

    return false
  end
end
