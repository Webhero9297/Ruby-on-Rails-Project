# encoding: utf-8
class Account
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection

  has_many :users
  has_many :listings, validate: false
  has_many :orders

  embeds_many :favorites, :class_name => 'Favorite'
  embeds_many :subscriptions, :class_name => 'Subscription'
  embeds_many :searches, :class_name => 'Search'
  embeds_many :message_templates, :class_name => 'MessageTemplate'
  embeds_one :contact, :class_name => "Contact", validate: false # Prevents Contact from being validated when changes are made on the account model
  embeds_one :contact_restrictions, :class_name => "ContactRestriction", validate: false
  embeds_one :profile, :class_name => "Profile"
  embeds_one :match_alert, :class_name => "MatchAlert"

  field :account_number,              type: Integer
  field :country_short,               type: String
  field :account_owner,               type: BSON::ObjectId
  field :activated_at,                type: DateTime, default: nil
  field :joined_at,                   type: DateTime
  field :newsletter,                  type: Boolean, default: false
  field :exchanges_made,              type: Integer, default: 0
  field :terminated,                  type: Boolean, default: false
  field :sent_listings,               type: Array, default: []
  field :awaiting_access,             type: Boolean, default: false
  field :agent_comment,               type: String
  field :last_login_at,               type: DateTime, default: nil
  field :time_zone,                   type: String, default: nil
  field :listing_numbers,             type: Array, default: []
  field :has_hidden_listing,          type: Boolean, default: false
  field :current_expires_at,          type: DateTime, default: nil
  field :accessed_at,                 type: DateTime, default: Date.today.to_time.utc
  field :beta_access,                 type: Boolean, default: false
  field :nr_of_allowed_listings,      type: Integer, default: 1
  field :last_reminder_sent,          type: DateTime

  field :has_received_exchange_dates_email_at, type: DateTime

  index :country_short

  validates_uniqueness_of :account_number
  validates_numericality_of :nr_of_allowed_listings

  def get_owner
    User.find(account_owner)
  end

  def get_listing_numbers
    ret = []
    self.listings.each do |listing|
      ret.push(listing.listing_number)
    end
    return ret.join(', ')
  end

  def manually_sync_data
    # current_expires_at
    self.set(:current_expires_at, current_subscription_expires_at.to_time)
    # listing_numbers
    numbers = []
    self.listings.each do |listing|
      numbers.push(listing.listing_number)
    end
    self.set(:listing_numbers, numbers)
  end


  def exchange_approval_requests?
    exchange_references = self.get_references
    account_id = self._id

    exchange_references.each do |ref|
      if ref.awaiting_approval(account_id)
        return true
      end
    end

    false
  end

  # FIXME: refactor
  def status
    begin
      if current_expires_at.blank?
        return "NO SUBSCRIPTION"
      end
      if current_expires_at < Date.today.to_time.utc
        return "Expired"
      end
      if awaiting_access
        return "Awaiting access"
      end
      if is_trial_subscription
        return "Free"
      end
      if is_paid_subscription
        return "Active"
      end
      return "NO SUBSCRIPTION"
    rescue
      return "NO SUBSCRIPTION"
    end
  end

  def get_references
    ExchangeReference.any_of({ account_id_1: self.id }, { account_id_2: self.id })
  end

  def get_visible_references
    all_ef = ExchangeReference.any_of({ account_id_1: self.id }, { account_id_2: self.id })

    visible = []

    all_ef.each do |ef|
      if ef.account_id_1.to_s != self.id.to_s
        if ef.act_as_reference_1 == true and ef.allow_as_reference_2 == true
          visible.push(ef.listing_number_1)
        end
      else
        if ef.act_as_reference_2 == true and ef.allow_as_reference_1 == true
          visible.push(ef.listing_number_2)
        end
      end
    end

    return visible
  end

  def has_reference?(listing_number)
    query = ExchangeReference.all_of(self.get_references.selector, ExchangeReference.any_of({listing_number_1: listing_number}, {listing_number_2: listing_number}).selector)

    if query.count > 0
      return true
    end
    return false
  end

  def set_time_zone(time_zone)
    update_attribute(:time_zone, time_zone)
  end

  def set_exchanges_made(exchanges_made)
    self.set(:exchanges_made, exchanges_made.to_i)
  end

  def set_joined_at(date)
    self.set(:joined_at, date.to_time )
  end

  def increment_exchanges_made
    # Can't use inc due to bug
    self.set(:exchanges_made, (self.exchanges_made + 1))
  end

  def transfer_to_country(country_short)
    self.set(:country_short, country_short)

    begin
      country = Country.where(short: country_short).first
      account_listing = AccountsListing.where(account_id: self._id).first
      account_listing.account_country_short = country_short
      account_listing.listing_country_code = country_short
      account_listing.listing_country = country.msgid
      account_listing.save
    rescue
      nil
    end
  end

  def has_active_listing?
    if self.listings.is_open_for_exchange.count > 0
      return true
    end
    return false
  end

  def can_create_listing?
    if self.listings.count < self.nr_of_allowed_listings
      return true
    end
    return false
  end

  def has_listing?
    if self.listings.count > 0
      return true
    end
    return false
  end

  def has_searchable_listing?
    listings.searchable.count > 0
  end

  def get_contact_address
    address = "#{self.contact.address} #{self.contact.postal_town} #{self.contact.postal_code}"
    return address
  end

  # Validate account profile
  def is_valid
    account_params = ValidProfile.get_validation_params(self)
    valid_account = ValidProfile.new(account_params)

    valid_account.valid?
  end

  # Return progress fro how complete the account profile is
  def get_progress
    account_params = ValidProfile.get_validation_params(self)
    valid_account = ValidProfile.new(account_params)
    valid_account.progress
  end

  ##
  # Sets the roles of the account users to restricted and deactivates the listings connected to the account
  def restrict_access_for_users
    self.users.each do |user|
      user.roles.delete('member')
      user.roles.delete('trial_member')
      user.roles.delete('restricted')
      user.roles.push('restricted')
      user.save
    end
  end

  def set_roles(roles)
    self.users.each do |user|
      user.roles = roles
      user.save
    end
  end

  def get_country
    Country.where(short: self.country_short).first
  end

  def remove_restrictions_for_users
    users.each do |user|
      roles = user.roles
      roles.delete('restricted')
      roles.push('member') unless roles.include?('member')

      user.update_attribute(:roles, roles)
    end
  end

  ##
  # Grants access to a awaiting access account. Removes restrictions from the connected users and sets the awaiting_access flag to false
  def grant_access
    self.awaiting_access = false

    remove_restrictions_for_users
    get_latest_subscription.activate
    save!
  end

  def self.stats_expires(countries=nil)
    accounts = Account.where(
      :subscriptions.matches=> {
        :active => true,
        :expires_at.gt => Time.now.utc,
        :expires_at.lt => 2.months.from_now.utc
      }
    )

    accounts = accounts.where(:country_short.in => countries) if countries

    stats = Account.collection.db.command({
      "aggregate" => "accounts",
      "pipeline" => [
        {"$match" => accounts.selector},
        {"$unwind" => "$subscriptions"},
        {"$match" => {"subscriptions.active" => true}},
        {"$project" => {
          "year" => { "$year" => "$subscriptions.expires_at"},
          "month" => { "$month" => "$subscriptions.expires_at"  }
        }},
        {"$group" =>
          { "_id" => {"year" => "$year", "month" => "$month" }, "count" => { "$sum" => 1 } }
        }]})['result']

    stats = stats.sort { |a, b| [a['_id']['year'], a['_id']['month']] <=> [b['_id']['year'], b['_id']['month']] }
    new_stats = []
    stats.each do |stat|
      date = Date.new(stat['_id']['year'], stat['_id']['month'])
      new_stats.push({'year_month' => I18n::l(date, format: :month_year).capitalize, 'count' => stat['count']})
    end
    new_stats
  end


  def self.stats_activated(for_countries=nil)
    from_date = 3.months.ago.utc
    accounts = Account.where(:joined_at.gt => from_date).where(:activated_at.ne => nil)
    if not for_countries.nil? then
      accounts = accounts.where(:country_short.in => for_countries)
    end
    stats = Account.collection.db.command({
      "aggregate" => "accounts",
      "pipeline" => [
        {"$match" => accounts.selector},
        {"$project" => {
          "year" => { "$year" => "$activated_at"},
          "month" => { "$month" => "$activated_at"  }
        }},
        {"$group" =>
          { "_id" => {"year" => "$year", "month" => "$month" }, "count" => { "$sum" => 1 } }
        }

        ]})['result']

    stats = stats.sort { |a, b| [a['_id']['year'], a['_id']['month']] <=> [b['_id']['year'], b['_id']['month']] }
    new_stats = []
    stats.each do |stat|
      date = Date.new(stat['_id']['year'], stat['_id']['month'])
      new_stats.push({'year_month' => I18n::l(date, format: :month_year).capitalize, 'count' => stat['count']})
    end
    new_stats
  end

  ##
  # Used for adding a order when a new paid account is created.
  # IMPORTANT Only used when creating new accounts via signup
  def add_order(price_plan, promotion_code, remote_ip)

    ##
    # Sets the total amount based on price plans base price.
    # If a promotion code is used the discounted price is calculated and assigned to total amount and the promotion code is added to the order.
    total_amount = price_plan.base_price
    code = nil
    if promotion_code != nil then
      total_amount = promotion_code.discounted_price.to_f
      code = promotion_code.code
    end

    ##
    # Assigns the PayPal Express destination subject even though the payment might not be through PayPal.
    if price_plan.country.paypal_email.blank?
     express_subject = Rails.application.config.paypal_options[:subject]
    else
      express_subject = price_plan.country.paypal_email
    end

    self.orders.create!(
      currency: price_plan.country.currency,
      total_amount: total_amount,
      ip_address: remote_ip,
      price_plan_id: price_plan.id,
      promotion_code: code,
      order_number: Order.make_order_number(price_plan.country.short),
      express_subject: express_subject
    )
  end


  def days_until_expire
    begin
      delta = (self.current_subscription.expires_at - Date.today)
      return delta.to_i
    rescue
      return 0
    end
  end

  def is_expired?
    self.current_expires_at < Date.today.to_time.utc
  end

  def is_expired_for_less_than_30_days?
    (self.current_expires_at + 30.days) > Date.today.to_time.utc
  end

  ##
  # Adds a subscription to the account.
  # Used in conjuction with a finsihed and successfull order
  def add_subscription(price_plan, order)
    # Check to see that order number has not already been used
    existing_subscription = self.subscriptions.where(order_number: order.order_number).first
    if existing_subscription
      return existing_subscription
    end

    base_time = Time.now.utc

    # If renewal or upgrade and the currnet subscription hasn't expired, prolong.
    if order['renewal'] == true or order['upgrade'] == true then
      if self.current_subscription and self.current_subscription.expires_at > base_time then
        base_time = self.current_subscription.expires_at
      end
    end

    if price_plan['periodicity'] == 'days' then
      expires_at = base_time + price_plan.duration.days
    else
      expires_at = base_time + price_plan.duration.years
    end

    subscription = self.subscriptions.create!(
      order_id: order.id,
      order_number: order['order_number'],
      base_price: price_plan['base_price'],
      renewal_price: price_plan['renewal_price'],
      name: price_plan['name'],
      duration: price_plan['duration'],
      periodicity: price_plan['periodicity'],
      kind: price_plan['kind'],
      promotion_code: order['promotion_code'],
      currency: order['currency'],
      renewal: order['renewal'],
      upgrade: order['upgrade'],
      active: false,
      expires_at: expires_at
    )

    return subscription
  end

  ##
  # Adds a subscription to the account.
  # Used in conjuction with a finsihed and successfull order
  # Used for special renewals
  def add_custom_subscription(params, order)
    # Check to see that order number has not already been used
    existing_subscription = self.subscriptions.where(order_number: order.order_number).first
    if existing_subscription
      return existing_subscription
    end

    base_time = Time.now.utc

    # If renewal or upgrade and the currnet subscription hasn't expired, prolong.
    if order['renewal'] == true or order['upgrade'] == true then
      if self.current_subscription and self.current_subscription.expires_at > base_time then
        base_time = self.current_subscription.expires_at
      end
    end

    if params[:periodicity] == 'days' then
      expires_at = base_time + params[:duration].days
    else
      expires_at = base_time + params[:duration].years
    end

    subscription = self.subscriptions.create!(
      order_id: order.id,
      order_number: order['order_number'],
      base_price: params[:base_price],
      renewal_price: params[:renewal_price],
      name: params[:name],
      duration: params[:duration],
      periodicity: params[:periodicity],
      kind: params[:kind],
      promotion_code: order['promotion_code'],
      currency: order['currency'],
      renewal: order['renewal'],
      upgrade: order['upgrade'],
      active: false,
      expires_at: expires_at
    )

    self.listings.update(open_past_listing: false)
    return subscription
  end

  def add_search(params)
    search = self.searches.where(name: params['filter_name']).first
    if search.nil?
      search = self.searches.new
    end
    search['name'] = params['filter_name']
    search['params'] = params
    search.save
  end

  def get_search(id)
    self.searches.find(id)
  rescue Mongoid::Errors::DocumentNotFound
    nil
  end

  def delete_search(id)
    self.searches.find(id).delete
  rescue Mongoid::Errors::DocumentNotFound
    nil
  end

  def get_saved_searches
    self.searches
  end

  # Sets the activation time for when the account was paid for and activated.
  def finish_registration()
    update_attributes(activated_at: Time.now.utc)
  end

  def current_subscription
    self.subscriptions.where(active: true).order_by([[:expires_at, :desc]]).first
  end

  def get_latest_subscription
    self.subscriptions.order_by([[:expires_at, :desc]]).first
  end

  def current_subscription_expires_at
    subscription = self.subscriptions.where(active: true).order_by([[:expires_at, :asc]]).first

    if subscription && subscription.expires_at
      # uses `.utc.to_time` to avoid problems with datetime and mongo
      subscription.expires_at.utc.to_time
    end
  end

  def is_trial_subscription
    current_subscription.kind == 'free'
  end

  def is_paid_subscription
    current_subscription.kind == 'paid'
  end

  def is_restricted
    get_owner.has_role(:restricted)
  end

  def get_subscription(subscription_id)
    subscriptions.find(subscription_id)
  end

  def get_favorites(listing_number=nil, member_name=nil)
    listings = Listing.
      where(:_id.in => favorites.map(&:listing_id)).
      where(:account_terminated => false).
      order(country_code: :asc)

    if listing_number
      listings = listings.select do |listing|
        listing.listing_number.match(/#{listing_number}/)
      end
    end

    if member_name
      listings = listings.select do |listing|
        listing.member_name.match(/#{member_name}/)
      end
    end

    listings
  end

  def get_favorite_notes
    favorites = {}

    self.favorites.each do |favorite|
      favorites[favorite.listing_id] = {note: favorite.note, id: favorite.id, created_at: favorite.created_at}
    end

    favorites
  end

  ##
  # Terminates the account and the associated users. The account and its listings are treated as archived
  # and will not be visible in searches or other public information. The account is left in the system to provide
  # correct statistics and history of conversations and exchange agreements.
  def self.terminate_account(account_id)
    account = Account.where(:_id => account_id).first
    return if account.nil?

    account.users.each do |user|
      user.update_attributes(terminated: true, email: "TERMINATED#{user.email}")
     end

    account.listings.each do |listing|
      listing.set(:account_terminated, true)
    end

    account.set(:terminated, true)
    account
  end

  # Adds a new favorite to the account document
  def add_as_favorite(listing_id, note = '')
    begin
      listing = Listing.find(listing_id)
      if listing.account == self
        return # Do not add own listings as favorite
      end
      self.favorites.create(listing_id: listing_id, note: note)

      if !listing.account.contact_restrictions.try(:added_as_favorite) && self.listings.any?
        NotificationMailer.added_favorite(listing.account.get_owner, self.get_owner, listing).deliver
      end

    rescue
      raise
    end
  end

  protected

  ##
  # Generates the account number
  def self.generate_account_number(passes = 1)
    # Get the highest current account number
    account = Account.unscoped.order_by([[ :account_number, :asc ]]).last
    # Default value for setting up a new empty server instance
    account_number = 141337

    # Return and exit if no current accounts exists
    return account_number if account.nil?

    # Increment the account number by 1
    account_number = account.account_number + 1

    # Test if the account number is available, if not generate a new number
    account = Account.where(account_number: account_number).last

    # Test for number of passes, if more than 10 passes raise exception
    nr_of_passes = passes + 1
    raise("Could not assign account number") if nr_of_passes > 10

    # If an account with the same account number is found run the generator again
    generate_account_number(nr_of_passes) unless account.nil?

    account_number
  end

  def self.build_new_account(params)
    timestamp = Time.now.utc

    # To avoid multiple callbacks on the parent object all embedded documents are built and timestamps are set manually
    account = Account.new(
        {
            account_number: Account.generate_account_number,
            country_short: params[:account][:country_short],
            joined_at: timestamp
        }
    )

    account.build_contact(
        {
            name: params[:user][:name],
            email: params[:user][:email],
            created_at: timestamp,
            updated_at: timestamp
        }
    )

    account.build_profile(
        {
            created_at: timestamp,
            updated_at: timestamp
        }
    )

    account.profile.build_presentation(
        {
            created_at: timestamp,
            updated_at: timestamp
        }
    )

    account.profile.build_lifestyle(
        {
            created_at: timestamp,
            updated_at: timestamp
        }
    )

    account.build_match_alert({})

    account
  end

  def add_message_template(name, subject, body, category='send')
    category = category.downcase
    allowed_categoris = ['send', 'reply']
    if not allowed_categoris.include?(category)
      category = 'send'
    end

    message_templates.create!(
      name: name,
      subject: subject,
      body: body,
      catgory: category
    )
  end


  # Creates a new listing and attach it to the current user account
  def create_new_listing(params)
    country_msgid = params[:listing][:country]
    country = Country.get_by_short(params[:listing][:country_code])
    if country
      country_msgid = country.msgid
    end

    listings.build(
      main_photo: params[:listing][:main_photo],
      lat: params[:listing][:lat].to_f,
      lng: params[:listing][:lng].to_f,
      street:  params[:listing][:street],
      postal_town:  params[:listing][:postal_town],
      postal_code:  params[:listing][:postal_code],
      state:  params[:listing][:state],
      state_long:  params[:listing][:state_long],
      country:  country_msgid,
      country_code:  params[:listing][:country_code],
      google_formatted_address: params[:listing][:google_formatted_address],
      location: [params[:listing][:lat].to_f, params[:listing][:lng].to_f],
      location_reversed: [params[:listing][:lng].to_f, params[:listing][:lat].to_f],
      account_country_short: self.country_short,
      account_expires_at: self.current_subscription_expires_at(),

      headline: params[:listing][:headline],
      description: params[:listing][:description],
      sleeping_capacity: params[:listing][:sleeping_capacity],
      property_type: params[:listing][:property_type],
      environment: params[:listing][:environment],
      property_details: [params[:listing][:children], params[:listing][:pets]],
      has_been_completed: true
    )
  end

  # Finds an account based on the contact email
  def self.find_by_email(email)
    account = self.where('contact.email' => email).first
    return account
  end

  # Finds one or several accounts based on account ids
  def self.find_by_ids(ids)
    self.where(:id.in => ids)
  end

  def self.find_by_name(name)
    where(:"contact.name" => /#{name}/i).order_by([[:"contact.name", :asc]])
  end

  def self.find_by_listing_number(number)
    where(:listing_numbers => /#{number}/i).order_by([[:"listing_numbers", :asc]])
  end

  def self.find_member_by_params(params, current_user)
    query = params[:q].strip
    listing = Listing.where("listing_number" => /^#{query.upcase}/i)

    if listing != nil then
      ids = []
      listing.each do |l|
        ids.push(l.account_id)
      end
      accounts = Account.any_of({:account_number=> query.to_i}, {:"contact.email"=> query}, {:"contact.name"=> /#{query}/i}, {:_id.in => ids})
    else
      accounts = Account.any_of({:account_number=> query.to_i}, {:"contact.email"=> query}, {:"contact.name"=> /#{query}/i})
    end

    if current_user
      countries = current_user.agent_profile.get_assigned_countries_short_codes
      accounts = accounts.any_in(:country_short => countries)
    end

    return accounts

    # Return early for now to see if this new search works :)

    if query.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
      return self.where(account_number: query.to_i).first
    end

    if query.include?('@')
      return self.where("contact.email" => query).first
    end

    listing = Listing.where("listing_number" => query.upcase).first

    if listing != nil then
      return listing.account
    end

    return nil
  end

  def self.filter_members_by_params(params)
    query = params[:filter]
    countries = params[:c]
    sort = params[:s]
    direction = params[:d]

    criteria = self
    if countries != 'all'
      criteria = self.where(:country_short.in => countries)
    end

    if sort and sort != 'listings'
      criteria = criteria.order_by(sort, direction)
    end

    case query
      when 'free'
        criteria = criteria.where(:"subscriptions.kind" => 'free').order_by(:"subscriptions.expires_at", :asc)
      when 'new'
        criteria = criteria.where(:"joined_at".gt => 60.days.ago).criteria.order_by(:joined_at, :desc)
      when 'expires'
        criteria = criteria.where(:subscriptions.matches => {:active => true, :expires_at.lt => Time.now.utc + 60.days, :expires_at.gt => Time.now.utc}).criteria.order_by(:"subscriptions.expires_at", :asc)
      when 'expired'
        criteria = criteria.where(:subscriptions.matches => {:active => true, :expires_at.lt => Time.now.utc}).order_by(:"subscriptions.expires_at", :desc)
      when 'activated'
        criteria = criteria.where(:activated_at.gt => 60.days.ago).order_by(:activated_at, :desc)
      when 'renewed'
        criteria = criteria.where(:"subscriptions.active" => true, :"subscriptions.renewal" => true, :created_at.gt => 60.days.ago.utc).order_by(:"subscriptions.created_at", :asc)
      when 'not_visible'
        l = Listing.searchable.only(:account_id)
        if countries != 'all'
          l = l.where(:account_country_short.in => countries)
        end
        listings_ids = l.map(&:account_id)
        criteria = criteria.where(:_id.nin => listings_ids)
      when 'no_listing'
        l = Listing.only(:account_id)
        if countries != 'all'
          l = l.where(:account_country_short.in => countries)
        end
        listings_ids = l.map(&:account_id)
        criteria = criteria.where(:_id.nin => listings_ids)
      else
        criteria = criteria.order_by(:created_at, :desc)
    end

    return criteria
  end

  def self.sort_and_filter_members_by_params(params)
    filter    = params[:filter]
    countries = params[:country_codes]
    direction = params[:direction]
    sort_on   = params[:sort]

    criteria = self

    unless params[:query].blank?
      query = params[:query].strip

      email = /[-0-9a-zA-Z.+_]+@[-0-9a-zA-Z.+_]+\.[a-zA-Z]{2,4}/
      number= /^[0-9]+$/
      listing = /^[a-zA-Z]{2,4}\d+/

      if email.match(query)
        criteria = self.where(:"contact.email" => query)
      elsif number.match(query)
        criteria = self.where(:account_number => query.to_i)
      elsif listing.match(query)
        criteria = self.where(:listing_numbers => query.upcase)
      else
        criteria = self.where(:"contact.name" => /#{query}/i)
      end
    end

    case filter
      when 'free'
        criteria = criteria.where(:subscriptions.matches => {:active => true, :expires_at.gt => Time.now.utc, :kind => 'free'})
      when 'new'
        criteria = criteria.where(:joined_at.gt => 60.days.ago.utc)
      when 'expires'
        criteria = criteria.where(:subscriptions.matches => {:active => true, :expires_at.lt => Time.now.utc + 60.days, :expires_at.gt => Time.now.utc})
      when 'expired'
        criteria = criteria.where(:subscriptions.matches => {:active => true, :expires_at.lt => Time.now.utc})
      when 'activated'
        criteria = criteria.where(:activated_at.gt => 60.days.ago.utc)
      when 'renewed'
        criteria = criteria.where(:subscriptions.matches => {:active => true, :renewal => true, :created_at.gt => 60.days.ago.utc})
      when 'no_listing'
        criteria = criteria.where(:listing_numbers.size => 0)
      when 'active'
        criteria = criteria.where(:subscriptions.matches => {:active => true, :expires_at.gt => Time.now.utc, :kind => 'paid'})
      when 'restricted'
        criteria = criteria.where(:awaiting_access => true)
    end

    criteria = criteria.where(:country_short.in => countries) unless countries.blank?

    # sorting
    case sort_on
      when 'name'
        criteria = criteria.order_by([:"contact.name", direction.to_sym])
      when 'email'
        criteria = criteria.order_by([:"contact.email", direction.to_sym])
      when 'country_short'
        criteria = criteria.order_by([:country_short, direction.to_sym])
      when 'expires_at'
        criteria = criteria.order_by([:current_expires_at, direction.to_sym])
      when 'listing'
        criteria = criteria.order_by([:listing_numbers, direction.to_sym])
      else
        criteria = criteria.order_by([:joined_at, :desc])
    end

    criteria
  end

  # Removes a favorite from the account document
  def remove_favorite(listing_id)
    self.favorites.delete_all(conditions: {listing_id: listing_id})
  end

  # Removes a favorite from the account document
  def remove_favorites(listing_ids)
    self.favorites.where(:listing_id.in => listing_ids).delete_all
  end

  ##
  # Returns all exchange agreemnts for the current account
  def get_all_exchange_partners
    account_ids = []
    exchange_partners = []

    self.exchange_agreements.each do |exchange_agreement|
      exchange_partners.push(exchange_agreement.get_partner_account_id(self.id))
    end

    partner_accounts = Account.find(exchange_partners)
  end

  def self.get_by_member_number(member_number)
    listing = Listing.where(:listing_number => member_number).first
    if listing.nil?
      return nil
    end
    return listing.account
  end

  ##
  # Scopes data mapper style. Methods that returns criteria can be treated as chainable scopes as well.
  class << self
    def active_account
      where(:terminated => false, :current_expires_at.gte => Date.today.to_time.utc)
    end

    def has_permission(asking_user)
      if asking_user.has_role(:agent) or asking_user.has_role(:admin)
        return where(terminated: false)
      end

      where(_id: asking_user.account_id).where(terminated: false)
    end

    def country_short(short)
      where(country_short: short)
    end

    def for_agent(countries_short)
      all_in(countries_short)
    end

    def limit_result
      limit(40)
    end

    def get_by_wish_list(lat, lng)
      where(:"profile.wish_list_destinations.ne_lat".gt => lat ).where(:"profile.wish_list_destinations.ne_lng".gt => lng ).where(:"profile.wish_list_destinations.sw_lat".lt => lat ).where(:"profile.wish_list_destinations.sw_lng".lt => lng )
    end

  end

  default_scope where(terminated: false)
  scope :all_accounts, where(:terminated.nin => ["", nil])
end
