# encoding: utf-8
class Search
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection

  embedded_in :account, :class_name => 'Account'

  field :name,              type: String
  field :q,                 type: String, default: ''
  field :lat,               type: Float, default: nil
  field :lng,               type: Float, default: nil
  field :ne_lat,            type: Float, default: nil
  field :ne_lng,            type: Float, default: nil
  field :sw_lat,            type: Float, default: nil
  field :sw_lng,            type: Float, default: nil
  field :zoom,                type: Integer, default: nil
  field :earliest_date,       type: Date, default: ''
  field :latest_date,         type: Date, default: ''
  field :environment,         type: String, default: ''
  field :sleeping_capacity,   type: Integer, default: 0
  field :filters,             type: Array, default: []
  field :match_alert,         type: Boolean, default: false
  field :destination,         type: String, default: nil
  field :country_code,        type: String, default: nil
  field :params,              type: Hash, default: {}

  validates_presence_of :name

  def set_match_alert(on=false)
    self.match_alert = on
    self.save
  end

  def get_results(account)
    current_user = User.find(account.account_owner)
    listings = Listing.searchable.only_international(current_user)

    if not self.ne_lat.blank?
      listings = listings.within_bounds(self.ne_lat, self.ne_lng, self.sw_lat, self.sw_lng)
    end

    ## Date check
    if not self.earliest_date.blank?
      earliest_date_utc = DateTime.parse(self.earliest_date).to_time.utc
      earliest_criteria = Listing.within_dates(earliest_date_utc)
      listings = listings.merge(earliest_criteria) if self.latest_date.blank?
    end

    if not self.latest_date.blank?
      latest_date_utc = DateTime.parse(self.latest_date).to_time.utc
      latest_criteria = Listing.within_dates(latest_date_utc)
      listings = listings.merge(latest_criteria) if self.earliest_date.blank?
    end

    if earliest_criteria and latest_criteria
      listings = listings.any_of([earliest_criteria.selector, latest_criteria.selector])
    end

    sleeping_capacity = 1
    if not self.sleeping_capacity.blank?
      sleeping_capacity = self.sleeping_capacity
      listings = listings.where(:sleeping_capacity.gte => sleeping_capacity)
    end

    if not self.environment.blank?
      listings = listings.where(:environment => self.environment)
    end

    active_tags = []
    if self.filters
      active_tags = self.filters
      listings = listings.all_in(property_details: active_tags)
    end

    listings
  end
end
