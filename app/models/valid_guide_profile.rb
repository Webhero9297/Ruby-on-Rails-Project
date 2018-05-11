# encoding: UTF-8
class ValidGuideProfile
  include ActiveAttr::Model
  include ActiveAttr::MassAssignment
  include ActiveModel::MassAssignmentSecurity
  include ActiveModel::ForbiddenAttributesProtection

  attribute :birthdate
  attribute :address
  attribute :postal_code
  attribute :postal_town
  attribute :county
  attribute :telephone
  attribute :mobile
  attribute :spoken_languages
  attribute :time_zone

  attr_accessible :birthdate, :address, :postal_code, :postal_town, :county, :telephone, :mobile, :spoken_languages, :time_zone

  validates_length_of :address, :in => 2..40, message: I18n.t('error.verify_street_address_is_correct')
  validates_length_of :postal_town, :in => 2..40, message: I18n.t('error.verify_city_is_correct')
  validates_presence_of :spoken_languages, message: I18n.t('error.select_at_least_one_language')

  validates :telephone, :presence => {:unless => Proc.new { |a| a.mobile.present? }, :length => {:minimum => 2, :maximum => 20 }, :message => I18n.t('error.must_enter_either_telephone_or_mobile')}
  validates :mobile, :presence => {:unless => Proc.new { |a| a.telephone.present? }, :length => {:minimum => 2, :maximum => 20 }, :message => I18n.t('error.must_enter_either_telephone_or_mobile')}
  # TODO Add strings to the locale file for human readable errors that matches the field labels.
end
