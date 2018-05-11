# encoding: UTF-8
class CoMember
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  
  attr_accessor :name, :email
  
  validates_presence_of :name, :message => ApplicationController.helpers.t('error.co_member.name.can_not_be_blank')
  validates_format_of :email, :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i, :message => ApplicationController.helpers.t('error.co_member.mail.must_be_valid')
  validate :unique_email
  
  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end
  
  
  def unique_email
    if User.exists?(conditions: { email: email })
      errors.add(:email, ApplicationController.helpers.t("error.co_member.email.already_exsists"))
    end
  end
  
  
  def persisted?
    false
  end
end