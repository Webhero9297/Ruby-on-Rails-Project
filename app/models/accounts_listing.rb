# This is only used to access the mapRedude collection accounts_listing
class AccountsListing
  include Mongoid::Document
  include Mongoid::Timestamps

  # All fields have default value of nil since the map reduce function sets null values to keep consistent
  field :account_id,                          type: BSON::ObjectId, default: nil #AccountID
  field :account_number,                      type: Integer, default: nil
  field :account_country_short,               type: String, default: nil
  field :account_activated_at,                type: DateTime, default: nil
  field :account_joined_at,                   type: DateTime, default: nil
  field :account_exchanges_made,              type: Integer, default: 0
  field :account_comment,                     type: String, default: nil
  field :account_terminated,                  type: Boolean, default: nil
  field :account_owner,                       type: BSON::ObjectId, default: nil #Account owner user ID
  field :awaiting_access,                     type: Boolean, default: false

  # Contact information
  field :contact_name,                        type: String, default: nil
  field :contact_address,                     type: String, default: nil
  field :contact_postal_code,                 type: String, default: nil
  field :contact_city,                        type: String, default: nil
  field :contact_state,                       type: String, default: nil
  field :contact_country,                     type: String, default: nil
  field :contact_phone,                       type: String, default: nil
  field :contact_mobile,                      type: String, default: nil
  field :contact_email,                       type: String, default: nil
  field :contact_fax,                         type: String, default: nil
  field :contact_web_site,                    type: String, default: nil

  # Profile
  field :profile_adults,                      type: String, default: nil
  field :profile_children,                    type: String, default: nil

  # Subscription
  field :subscription_active,                 type: Boolean, default: nil
  field :subscription_kind,                   type: String, default: nil
  field :subscription_renewal,                type: Boolean, default: nil
  field :subscription_upgrade,                type: Boolean, default: nil
  field :subscription_expires_at,             type: DateTime, default: nil
  field :subscription_created_at,             type: DateTime, default: nil

  # Listing information
  field :listing_id,                          type: BSON::ObjectId, default: nil #ListingID
  field :listing_number,                      type: String, default: nil
  field :listing_street,                      type: String, default: nil
  field :listing_postal_town,                 type: String, default: nil
  field :listing_postal_code,                 type: String, default: nil
  field :listing_country,                     type: String, default: nil
  field :listing_country_code,                type: String, default: nil
  field :listing_google_formatted_address,    type: String, default: nil
  field :listing_active,                      type: Boolean, default: nil
  field :listing_updated_at,                  type: DateTime, default: nil
  field :exchange_dates_latest_date,          type: DateTime, default: nil

  default_scope where(account_terminated: false)

  def self.find_member_by_params(params, country_codes)
    
    query = params[:q].strip
    
    accounts = self.any_of({:account_number => query.to_i}, {:listing_number => /^#{query.upcase}/}, {:contact_email => query}, {:contact_name => /#{query}/i})
    accounts = accounts.any_in(:account_country_short => country_codes)

    return accounts
  end

  def account_status
    begin
      if subscription_expires_at.blank?
        return "NO SUBSCRIPTION"
      end
      if subscription_expires_at < Date.today.to_time.utc
        return "Expired"
      end
      if awaiting_access == true
        return "Awaiting access"
      end
      if subscription_active and subscription_kind == 'free'
        return "Trial"
      end
      if subscription_active and subscription_kind == 'paid'
        return "Active"
      end
      return "NO SUBSCRIPTION"
    rescue Exception => e
      return "NO SUBSCRIPTION"
    end
    return "NO SUBSCRIPTION"
  end

  ##
  # Used by the find by member name on the member dashboard landing page
  def self.find_by_member_name(query)
    if query.blank?
      return {}
    end
    query = query.strip
    self.where(:contact_name => /#{query}/i).order_by([[:contact_name, :asc]])
  end

  ##
  # Used by the find by member name on the member dashboard landing page
  def self.find_by_listing_number(query)
    if query.blank?
      return {}
    end
    query = query.strip.upcase
    self.where(:listing_number => /#{query}/).order_by([[:listing_number, :asc]])
  end


  def self.sort_and_filter_members_by_params(params)
    
    
    filter = params[:filter]
    countries = params[:country_codes]
    direction = params[:direction]
    sort_on = params[:sort]
    
    criteria = self

    if not params[:query].blank?
      query = params[:query].strip
      criteria = self.any_of({:account_number => query.to_i}, {:listing_number => /^#{query.upcase}/i}, {:contact_email => query}, {:contact_name => /#{query}/i})
      #criteria = criteria.any_in(:account_country_short => country_codes)
    end
    

    case filter
      when 'free'
        criteria = criteria.where(:subscription_kind => 'free')
      when 'new'
        criteria = criteria.where(:account_joined_at.gt => 60.days.ago.utc)
      when 'expires'
        criteria = criteria.where(:subscription_expires_at.lt => Time.now.utc + 60.days, :subscription_expires_at.gt => Time.now.utc)
      when 'expired'
        criteria = criteria.where(:subscription_expires_at.lt => Time.now.utc)
      when 'activated'
        criteria = criteria.where(:account_activated_at.gt => 60.days.ago.utc)
      when 'renewed'
        criteria = criteria.where(:subscription_active => true, :subscription_renewal => true, :subscription_created_at.gt => 60.days.ago.utc)
      when 'not_visible'
        criteria = criteria.any_of({:listing_active => false}, {:subscription_expires_at.lt => Time.now.utc}, {:exchange_dates_latest_date.lt => Time.now.utc})
      when 'no_listing'
        criteria = criteria.where(:listing_id => nil)
      when 'active'
        criteria = criteria.where(:subscription_expires_at.gte => Time.now.utc).where(:subscription_kind => 'paid').where(:awaiting_access => false)
      when 'awaiting_access'
        criteria = criteria.where(:awaiting_access => true)
      else
        ''
    end
    
    criteria = criteria.where(:account_country_short.in => countries)

    # sorting
    case sort_on
      when 'name'
        criteria = criteria.order_by([:contact_name, direction.to_sym])
      when 'email'
        criteria = criteria.order_by([:contact_email, direction.to_sym])
      when 'country_short'
        criteria = criteria.order_by([:account_country_short, direction.to_sym])
      when 'expires_at'
        criteria = criteria.order_by([:subscription_expires_at, direction.to_sym])
      when 'listing'
        criteria = criteria.order_by([:listing_number, direction.to_sym])
      else
        criteria = criteria.order_by([:account_joined_at, :desc])
    end

    return criteria

  end
  
end
