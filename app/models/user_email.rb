class UserEmail
  include ActiveAttr::Model
  include ActiveAttr::MassAssignment
  include ActiveModel::MassAssignmentSecurity
  
  attribute :email
  attribute :secondary_email
  attribute :current_email
  attr_accessor :email, :current_email, :secondary_email

  validates_format_of :current_email, :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i, :message => 'Current email'
  validates_format_of :email, :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i, :message => 'Verify that the email address is correct', :unless => Proc.new { |a| a.secondary_email.present? }
  validates_format_of :secondary_email, :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i, :message => 'Verify that the email address is correct', :unless => Proc.new { |a| a.email.present? }
  validate :unique_email, :unless => Proc.new { |a| a.secondary_email.present? }
  validate :unique_secondary_email, :unless => Proc.new { |a| a.email.present? }
  
  def unique_email
    user = User.where(email: self.email).first
    
    if self.email != self.current_email and not user.nil? then
      errors.add(:email, I18n.t('error.email_already_taken'))
      return
    end
  end

  def unique_secondary_email
    user = User.where(secondary_email: self.secondary_email).first
    
    if self.secondary_email != self.current_email and not user.nil? then
      errors.add(:email, I18n.t('error.email_already_taken'))
      return
    end
  end
end
