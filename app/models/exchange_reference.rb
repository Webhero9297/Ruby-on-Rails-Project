class ExchangeReference
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  
  field :listing_number_1,      type: String
  field :account_id_1,          type: BSON::ObjectId
  field :act_as_reference_1,    type: Boolean, default: nil
  field :allow_as_reference_1,  type: Boolean, default: false
  field :start_date,            type: DateTime
  field :end_date,              type: DateTime
  field :listing_number_2,      type: String
  field :account_id_2,          type: BSON::ObjectId
  field :act_as_reference_2,    type: Boolean, default: nil
  field :allow_as_reference_2,  type: Boolean, default: false
  field :exchange_agreement_id, type: BSON::ObjectId

  attr_accessor :is_request

  validates_presence_of :listing_number_1, :listing_number_2, :account_id_1, :account_id_2

  validates :exchange_agreement_id, uniqueness: true, :if => :not_request_reference?


  def not_request_reference?
    if is_request.nil?
      return true
    end

    false
  end


  def self.add_references(exchange_references)
    self.create!(
      :listing_number_1 => exchange_references[:listing_number_1],
      :account_id_1 => exchange_references[:account_id_1],
      :start_date => exchange_references[:start_date],
      :end_date => exchange_references[:end_date],
      :listing_number_2 => exchange_references[:listing_number_2],
      :account_id_2 => exchange_references[:account_id_2],
      :exchange_agreement_id => exchange_references[:exchange_agreement_id]
    )
  end



  def self.request_reference(exchange_reference)
    self.create!(
      :listing_number_1 => exchange_reference[:listing_number_1],
      :account_id_1 => exchange_reference[:account_id_1],
      :start_date => exchange_reference[:start_date],
      :end_date => exchange_reference[:end_date],
      :listing_number_2 => exchange_reference[:listing_number_2],
      :account_id_2 => exchange_reference[:account_id_2],
      :act_as_reference_1 => true,
      :act_as_reference_2 => nil,
      :allow_as_reference_1 => true,
      :allow_as_reference_2 => false,
      :is_request => true
    )
  end

  ##
  # Checks if a exchange reference is awaiting approval
  def awaiting_approval(account_id)

    is_ref = 0

    if account_id == self.account_id_1
      is_ref = 1
    end

    if account_id == self.account_id_2
      is_ref = 2
    end

    if self["act_as_reference_#{is_ref}"].nil?
      return true
    end

    false
  end


end