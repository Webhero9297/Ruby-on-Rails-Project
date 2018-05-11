class Agreement
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  
  embedded_in :exchange_agreement, :class_name => "ExchangeAgreement"
  
  field :listing_id,                  type: BSON::ObjectId
  field :listing_number,              type: String
  field :listing_location,            type: String
  field :listing_country,             type: String
  field :listing_country_code,        type: String
  
  field :owner,                       type: BSON::ObjectId
  field :start_date,                  type: DateTime
  field :end_date,                    type: DateTime
  field :participants,                type: Array, default: []
  field :sent,                        type: Boolean, default: false
  
  embeds_one :car_exchange,           :class_name => 'Term'
  embeds_one :long_distance_calls,    :class_name => 'Term' 
  embeds_one :cleaning,               :class_name => 'Term'
  embeds_one :key_exchange,           :class_name => 'Term'
  embeds_one :pets,                   :class_name => 'Term'
  embeds_one :other,                  :class_name => 'Term'

  accepts_nested_attributes_for :car_exchange, :long_distance_calls, :cleaning, :key_exchange, :pets, :other
  
  field :has_car_insurance,           type: Boolean, default: false
  field :show_mobile,                 type: Boolean, default: false
  field :show_email,                  type: Boolean, default: false
  field :guests_allowed,              type: Boolean, default: false
  field :pets_allowed,                type: Boolean, default: false
  field :use_linen,                   type: Boolean, default: false
  field :cancellation_help,           type: Boolean, default: true
  field :feature_interview,           type: Boolean, default: false
  field :act_as_reference,            type: Boolean, default: false
  field :allow_as_reference,          type: Boolean, default: true
  field :feedback_sent,               type: Boolean, default: false
  field :welcome_sent,                type: Boolean, default: false

  validate :latest_date_must_be_higher_than_earliest
  
  
  def latest_date_must_be_higher_than_earliest
    return if start_date.blank? or end_date.blank?
    if start_date > end_date
      errors.add(:start_date, "must be earlier than end date")
    end
  end


  def can_be_signed?
    if self.all_terms_accepted? and self.participants.length > 0
      return true
    end
    return false
  end
  
  def is_ready_for_review?
    if self.start_date.blank? or self.end_date.blank? or self.participants.length == 0
      return false
    end
    return true
  end
  
  def all_terms_accepted?
    terms = ['car_exchange', 'long_distance_calls', 'cleaning', 'key_exchange', 'pets', 'other']
    terms.each do |term|
      if self[term]['accepted_by_partner'] == false or self[term]['accepted_by_partner'] == nil then
        return false
      end
    end
    return true
  end
  
  def has_rejections?
    terms = ['car_exchange', 'long_distance_calls', 'cleaning', 'key_exchange', 'pets', 'other']
    terms.each do |term|
      if self[term]['accepted_by_partner'] == false then
        return true
      end
    end
    return false
  end

  def clear_rejections

    terms = [ self.car_exchange, self.long_distance_calls, 
              self.cleaning, self.key_exchange, self.pets, 
              self.other]
    terms.each do |term|
      if term.accepted_by_partner == false then
        term.accepted_by_partner = nil
        term.save!
      end
    end
  end
  
  def clear_all

    terms = [ self.car_exchange, self.long_distance_calls, 
              self.cleaning, self.key_exchange, self.pets, 
              self.other]
    terms.each do |term|
      term.accepted_by_partner = nil
      term.save!
    end
  end
  
  def owner_account
    Account.find(self.owner)
  end
  
end
