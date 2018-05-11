# encoding: utf-8
class Contact
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  embedded_in :account, :class_name => "Account"

  field :name,          type: String, default: ''
  field :birthdate,     type: Time
  field :address,       type: String, default: ''
  field :postal_town,   type: String, default: ''
  field :postal_code,   type: String, default: ''
  field :county,        type: String, default: ''
  field :telephone,     type: String, default: ''
  field :mobile,        type: String, default: ''
  field :fax,           type: String, default: ''
  field :email,         type: String, default: ''
  field :skype,         type: String, default: ''
  field :website,       type: String, default: ''
  field :complete,      type: Boolean, default: false

  attr_accessor :contact_page

  validates_presence_of :name, message: I18n.t('error.missing_name')
  validates_presence_of :email, message: I18n.t('error.missing_email')
  validates_presence_of :address, message: I18n.t('error.verify_street_address_is_correct'), if: :is_contact_page?
  validates_presence_of :postal_town, message: I18n.t('error.verify_city_is_correct'), if: :is_contact_page?
  validates_format_of :email, :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i

  validates :telephone, :presence => {:unless => Proc.new { |a| a.mobile.present? }, :length => {:minimum => 2, :maximum => 20 }, :message => I18n.t('error.must_enter_either_telephone_or_mobile')}, :if => :is_contact_page?
  validates :mobile, :presence => {:unless => Proc.new { |a| a.telephone.present? }, :length => {:minimum => 2, :maximum => 20 }, :message => I18n.t('error.must_enter_either_telephone_or_mobile')}, :if => :is_contact_page?

  ##
  # Checks if the param contact_page is available in the params or not.
  # Better to check if the value is nil or not instead of checking for an actual boolean value due to the nature of attr_accessor
  def is_contact_page?
    if not contact_page.nil?
      return true
    end

    return false
  end
end
