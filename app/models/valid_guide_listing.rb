# encoding: utf-8
class ValidGuideListing
  include ActiveAttr::Model
  include ActiveAttr::MassAssignment
  include ActiveModel::MassAssignmentSecurity
  include ActiveModel::ForbiddenAttributesProtection
    
  attribute :headline
  attribute :description
  attribute :sleeping_capacity
  attribute :property_type
  attribute :environment
  attribute :children
  attribute :pets
  attribute :main_photo
  attribute :earliest_date
  attribute :latest_date
  attribute :lat
  attribute :lng
  attribute :street
  attribute :postal_town
  attribute :postal_code
  attribute :state
  attribute :state_long
  attribute :country
  attribute :country_code
  attribute :google_formatted_address
  attribute :main_photo_cache
  
  attr_accessible :headline, :description, :sleeping_capacity, :property_type, :environment, 
                  :children, :pets, :main_photo, :main_photo_cache, :earliest_date, :latest_date, :lat, :lng, :street, :postal_town, :postal_code,
                  :state, :state_long, :country, :country_code, :google_formatted_address
  
  validates_presence_of :headline, :message => I18n.t('error.missing_headline')
  validates_presence_of :description, :message => I18n.t('error.missing_description')
  validates_presence_of :property_type, :message => I18n.t('error.missing_property_type') 
  validates_presence_of :environment, :message => I18n.t('error.missing_environment_setting_for_home')
  validates_presence_of :sleeping_capacity, :message => I18n.t('error.missing_sleeping_capacity_for_home')
  validates_presence_of :children, :message => I18n.t('error.missing_allow_children_setting') 
  validates_presence_of :pets, :message => I18n.t('error.missing_allow_pets_setting') 
  validate :latest_date_must_be_higher_than_earliest
  validates_presence_of :main_photo, :message => I18n.t('error.missing_home_photo') 
  
  # TODO Add strings to the locale file for human readable errors that matches the field labels.

  def latest_date_must_be_higher_than_earliest
    return if earliest_date.blank? or latest_date.blank?
    if earliest_date > latest_date
      errors.add(:earliest_date, I18n.t('error.require_earlier_than_latest_date'))
    end
  end
end
