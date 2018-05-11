class UkDetailsPaymentForm
  include ActiveAttr::Model
  include ActiveAttr::MassAssignment
  include ActiveModel::MassAssignmentSecurity
  include ActiveModel::ForbiddenAttributesProtection

  attribute :first_name
  attribute :last_name
  attribute :phone
  attribute :street
  attribute :city
  attribute :postal

  attr_accessible :first_name, :last_name, :email, :phone, :street, :city, :postal

  validates_length_of :first_name, :in => 2..40, :message => 'Please fill out your first name'
  validates_length_of :last_name, :in => 2..40, :message => 'You must provide your last name'
  validates_length_of :phone, :in => 2..40, :message => 'You must provide a valid phone number'
  validates_length_of :street, :in => 2..40, :message => 'You must provide your street address'
  validates_length_of :postal, :in => 2..40, :message => 'You must provide your postal code'
  validates_length_of :city, :in => 2..40, :message => 'You must provide your city name'

end
