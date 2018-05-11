class ExchangeAgreement
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  
  field :parties,           type: Array
  field :status,            type: String, default: 'started' #{'started'=>20, 'ready_for_review'=>30,'negotiating'=>50, 'accepted'=>75, 'signed'=>90, 'agreed'=>100}
  field :accepted_by,       type: Array, default: []
  field :signed_by,         type: Array, default: []
  field :started_by,        type: BSON::ObjectId
  field :show_notification, type: Array, default: []
  
  
  embeds_many :agreements, :class_name => "Agreement"
  embeds_many :activities, :class_name => "ExchangeAgreementActivity"

  accepts_nested_attributes_for :agreements, :activities
  
  ##
  # Builds a new exchange agreement. The method does not save the agreement.
  def self.build_agreement(member_listing, partner_listing)
    exchange_agreement = self.new(
      parties: [member_listing.account.id, partner_listing.account.id],
      accepted_by: [member_listing.account.id],
      started_by: member_listing.account.id
    )
    
    member_agreement = exchange_agreement.agreements.build(
      owner: member_listing.account.id,
      listing_id: member_listing.id,
      listing_number: member_listing.listing_number,
      listing_location: member_listing.postal_town,
      listing_country: member_listing.country,
      listing_country_code: member_listing.country_code
    )
    member_agreement.build_car_exchange
    member_agreement.build_long_distance_calls
    member_agreement.build_cleaning
    member_agreement.build_key_exchange
    member_agreement.build_pets
    member_agreement.build_other
    
    partner_agreement = exchange_agreement.agreements.build(
      owner: partner_listing.account.id,
      listing_id: partner_listing.id,
      listing_number: partner_listing.listing_number,
      listing_location: partner_listing.postal_town,
      listing_country: partner_listing.country,
      listing_country_code: partner_listing.country_code
    )
    partner_agreement.build_car_exchange
    partner_agreement.build_long_distance_calls
    partner_agreement.build_cleaning
    partner_agreement.build_key_exchange
    partner_agreement.build_pets
    partner_agreement.build_other
    
    return exchange_agreement
    
  end
  
  def is_signed_by(id)
    if self.signed_by.include?(id)
      return true
    end
    return false
  end
  
  def cancel(current_user)
    active_statuses = ['started', 'ready_for_review', 'negotiating', 'accepted', 'signed']
    if active_statuses.include?(self.status) then
      self.set(:status, 'cancelled')
      self.create_activity('cancelled', current_user)
      return true
    end
    return false
  end
  
  
  def sign(current_user)
    self.add_to_set(:signed_by, current_user.account.id)
    self.set(:status, 'signed')
    self.create_activity('signed', current_user)
    
    # TODO Make a better check
    if self.signed_by.length == 2
      self.set(:status, 'agreed')
    end
    
  end
  
  def create_activity(activity, user)
    
    activities = {
      'started' => 'exchange_agreement.started',
      'signed' => 'exchange_agreement.signed',
      'created' => 'exchange_agreement.created',
      'viewed' => 'exchange_agreement.viewed',
      'cancelled' => 'exchange_agreement.cancelled',
      'term_declined' => 'exchange_agreement.term_declined',
      'term_accepted' => 'exchange_agreement.term_accepted',
      'updated' => 'exchange_agreement.updated'
    }
    
    self.activities.create!(
      activity: activities[activity],
      performed_by: user.name,
      user_id: user.id
    )
  end

  def get_activity_for_account(activity, account_id)

    users = Account.unscoped.find(account_id).users
    ids = []
    users.each do |user|
      ids.push(user.id)
    end

    return self.activities.where(:activity => activity).where(:user_id.in => ids).order_by(:created_at, :desc).first
  end

  # Checks is the partner has made any changes the we have not seen
  def new_activity_check(account_id)
    users = Account.find(account_id).users
    ids = []
    users.each do |user|
      ids.push(user.id)
    end

    last_activity = self.activities.where(:activity.ne => "exchange_agreement.viewed").order_by(:created_at, :desc).first
    if ids.include?( last_activity.user_id )
      return false
    end
    return last_activity
  end

  def get_activity_timestamp(activity)
    activities = {
      'started' => 'exchange_agreement.started',
      'signed' => 'exchange_agreement.signed',
      'created' => 'exchange_agreement.created',
      'viewed' => 'exchange_agreement.viewed',
      'cancelled' => 'exchange_agreement.cancelled',
      'term_declined' => 'exchange_agreement.term_declined',
      'term_accepted' => 'exchange_agreement.term_accepted',
      'updated' => 'exchange_agreement.updated'
    }

    activity_obj = self.activities.where(:activity => activities[activity]).order_by(:created_at, :desc).first
    if activity_obj
      return activity_obj.created_at
    end
    return nil
  end


  def is_valid?
    if self.can_be_agreed? == false
      return false
    end
    if self.agreements[0].participants.empty?
      return false
    end
    if self.agreements[1].participants.empty?
      return false
    end
    return true
  end
  
  
  def can_be_signed?
    
    self.agreements.each do |agreement|
      if not agreement.can_be_signed?
        return false
      end
    end
    return true
  end
  
  def get_other_agreement(agreement)
    oa = self.agreements.where(:listing_id.ne => agreement.listing_id).first
    return oa
  end
  
  
  def set_as_agreed
    self.status = 'agreed'
    self.save
  end
  
  def send_to(id)
    self.sent_to.push(id)
    self.save
  end
  
  ##
  # Returns the partner account id by returning the the id that doesn't match the current user.
  def get_partner_account_id(current_user_account_id)
    
    self.parties.each do |party|
      if party != current_user_account_id then
        return party
      end
    end
    
    return nil
  end
  
  
  class << self
    
    def by_owner(account_id)
      where('agreements.owner' => account_id)
    end
    
    
    def future
      where(:status => 'agreed').where(:"agreements.end_date".gt => Time.now.utc)
    end
    
    
    def past
      where(:status => 'agreed').where(:"agreements.end_date".lte => Time.now.utc)
      
    end

    def cancelled
      where(:status => 'cancelled')
    end
    
    def active
      where(:status.in => ['started', 'request_accepted', 'negotiating', 'signed', 'ready_for_review', 'accepted'])
    end
    
    def future_dates
      any_of({:"agreements.end_date".gt => Time.now.utc}, {:"agreements.end_date" => nil})
    end

    def agent_members(country_short_codes)
      where(:"agreements.listing_country_code".in => country_short_codes)
    end
    
    
    def last_edited_by_partner(current_user)
      where(:"agreements.activities.user_id".ne => current_user)
    end
    
  end
end
