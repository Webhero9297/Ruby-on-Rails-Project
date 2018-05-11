class ActiveListing
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :headline, :description, :environment, :property_type, :main_photo, :sleeping_capacity, :property_details

  validates_presence_of :headline, :description, :environment, :property_type, :main_photo
  validates_numericality_of :sleeping_capacity, :greater_than_or_equal_to => 1

  validate :children_preferences
  validate :pets_preferences

  FINISHED_COUNT = 8

  def children_preferences
    if  property_details.include?('tag.no_small_children') or property_details.include?('tag.children_welcome')
      return
    end
    errors.add(:children_preferences, I18n.t('error.missing_allow_children_setting'))
  end

  def pets_preferences
    if property_details.include?('tag.no_pets') or property_details.include?('tag.pets_welcome')
      return
    end
    errors.add(:pets_preferences, I18n.t('error.missing_allow_pets_setting'))
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
    progress = ( (ActiveListing::FINISHED_COUNT - errors_count).to_f / ActiveListing::FINISHED_COUNT.to_f * 100 ).to_i
    if progress == 0
      progress = 3
    end
    return progress
  end

  ##
  # Sets all the parameters that needs to be validated before a listing can go live.
  def self.get_validation_params(listing)

    params = {
      headline: listing.headline,
      description: listing.description,
      environment: listing.environment,
      property_type: listing.property_type,
      sleeping_capacity: listing.sleeping_capacity,
      property_details: listing.property_details,
      main_photo: listing.get_main_photo
    }

    return params
  end

  ##
  #
  def is_missing_field(field)

    if self.errors.messages.has_key?(field)
      return true
    end

    return false
  end
end
