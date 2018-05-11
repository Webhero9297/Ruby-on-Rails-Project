# encoding: utf-8
require 'ostruct'

class Listing
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection

  mount_uploader :main_photo, MainPhotoUploader

  belongs_to :account

  has_many :statistics, :class_name => ListingStatistic.to_s

  embeds_many :exchange_dates, :class_name => ExchangeDate.to_s
  embeds_many :listing_images, :class_name => ListingImage.to_s

  accepts_nested_attributes_for :listing_images

  attr_accessor :by_agent, :image_width, :image_height

  # Remember that the search for match alert uses the same params as the
  # listing search. In case you add any new param here, it's important to
  # change the Match Alert search to reflect that as well.
  field :active,                    type: Boolean, default: true
  field :listing_number,            type: String, default: nil
  field :last_updated,              type: DateTime, default: Time.now
  field :open_for_exchange,         type: Boolean, default: true

  field :street,                    type: String, default: ''
  field :postal_town,               type: String, default: ''
  field :postal_code,               type: String, default: ''
  field :country,                   type: String, default: ''
  field :state,                     type: String, default: ''
  field :state_long,                type: String, default: ''
  field :country_code,              type: String, default: ''
  field :google_formatted_address,  type: String, default: ''
  field :custom_nearest_city,       type: String, default: ''
  field :custom_country,            type: String, default: ''
  field :airport,                   type: String, default: ''
  field :distance,                  type: String, default: ''
  field :headline,                  type: String, default: ''
  field :description,               type: String, default: ''
  field :sleeping_capacity,         type: Integer, default: 0
  field :bedrooms,                  type: Integer, default: 0
  field :bathrooms,                 type: Integer, default: 0
  field :property_type,             type: String, default: '' #msgid
  field :floor,                     type: String, default: ''

  field :location,                  type: Array, default: [0.0, 0.0]
  field :location_reversed,         type: Array, default: [0.0, 0.0]
  field :lat,                       type: Float, default: 0.0
  field :lng,                       type: Float, default: 0.0
  field :environment,               type: String, default: '' #msgid
  field :property_details,          type: Array, default: []  #msgid
  field :bicycles,                  type: Integer, default: 0

  field :surrounding,               type: String, default: ''
  field :surroundings,              type: Array, default: []

  field :exchange_types,            type: Array, default: ['exchangetype.exchange_of_home'] #msgid

  field :added_to_hot_list,         type: DateTime, default: nil
  field :page_views,                type: Integer, default: 0
  field :map_visibility,            type: String, default: 'guests' # guests, members, hidden

  #area of property
  field :living_area, type: Integer
  field :living_area_unit, type: String

  field :total_area, type: Integer
  field :total_area_unit, type: String

  field :match_alert_expires,       type: Time, default: nil

  field :need_confirmation,         type: Boolean, default: false
  field :searchable,                type: Boolean, default: false
  field :has_been_completed,        type: Boolean, default: false
  field :open_past_listing,         type: Boolean, default: false
  # Main photo
  field :main_photo_caption,        type: String, default: ''
  field :main_photo_path,           type: String, default: ''

  # Account data for searching
  field :account_expires_at,                type: DateTime, default: nil
  field :account_wish_lists,                type: Array, default: []
  field :account_terminated,                type: Boolean, default: false
  field :account_country_short,             type: String, default: ''
  field :account_children,                  type: Integer, default: 0
  field :account_adults,                    type: Integer, default: 0
  field :account_pets,                      type: Integer, default: 0
  field :account_open_for_all_destinations, type: Boolean, default: true
  field :account_spoken_languages,          type: Array, default: []
  field :account_exchanges_made,            type: Integer, default: 0

  index [[ :location, Mongo::GEO2D ]], min: -180, max: 180
  index(
      [
        [ :active, 1 ],
        [ :account_expires_at, 1 ],
        [ :account_terminated, 1 ]
      ])

  index :listing_number, unique: true

  attr_accessor :main_photo_placeholder

  validates_presence_of :location
  validates_numericality_of :lat, :lng, :greater_than_or_equal_to => -180, :less_than_or_equal_to => 180

  validate :correct_location

  # Move this validation to somewhere else
  validate :correct_surroundings

  validates_presence_of :headline, :message => I18n.t('error.missing_headline')
  validates_presence_of :country, :message => I18n.t('error.missing_location')
  validates_presence_of :country_code, :message => I18n.t('error.unable_define_country_code_for_location')
  validates_presence_of :description, :message => I18n.t('error.missing_description')
  validates_presence_of :property_type, :message => I18n.t('error.missing_property_type')
  validates_presence_of :environment, :message => I18n.t('error.missing_environment_setting_for_home')
  validates_presence_of :sleeping_capacity, :message => I18n.t('error.missing_sleeping_capacity_for_home')
  validates_presence_of :children, :message => I18n.t('error.missing_allow_children_setting')
  validates_presence_of :pets, :message => I18n.t('error.missing_allow_pets_setting')
  validates_presence_of :main_photo, :message => I18n.t('error.missing_home_photo'), :if => :no_placeholder?

  validates_uniqueness_of :listing_number
  validates :listing_number, format: { with: /^[A-Z]{2,4}\d+/, on: :update, message: I18n.t('error.incorret_format_start_2_4_capital_letters')}

  before_create :create_listing_number, :set_path
  after_create :add_listing_number_to_account
  after_destroy :remove_listing_number_from_account

  SURROUNDING_TYPES = [
      {short: 'beach', msgid: 'listing.label.surrrounding.beach'},
      {short: 'boating', msgid: 'listing.label.surrrounding.boating'},
      {short: 'golfing', msgid: 'listing.label.surrrounding.golfing'},
      {short: 'forest', msgid: 'listing.label.surrrounding.forest'},
      {short: 'river', msgid: 'listing.label.surrrounding.river'},
      {short: 'sea', msgid: 'listing.label.surrrounding.sea'},
      {short: 'lake', msgid: 'listing.label.surrrounding.lake'},
      {short: 'shopping', msgid: 'listing.label.surrrounding.shopping'},
      {short: 'mountains', msgid: 'listing.label.surrrounding.mountains'}
  ]

  LISTING_PLACEHOLDER_IMAGES = {
    house: "#{Rails.root}/app/assets/images/no-photos-house.jpg",
    villa: "#{Rails.root}/app/assets/images/no-photos-villa.jpg",
    apartment: "#{Rails.root}/app/assets/images/no-photos-apartment.jpg"
  }

  def member_name
    self.account.get_owner.name
  end

  def city_and_country_headline
    hl_town    = postal_town
    hl_country = I18n.t(country)

    hl_town    = custom_nearest_city unless custom_nearest_city.blank?
    hl_country = custom_country      unless custom_country.blank?

    [hl_town, hl_country]
  end

  def update_custom_city_and_country(city, country)
    self.custom_nearest_city = city
    self.custom_country = country
    save
  end

  def no_placeholder?
    main_photo_placeholder.blank?
  end

  def children
    return 'tag.children_welcome' if self.property_details.include?('tag.children_welcome')
    return 'tag.no_small_children' if self.property_details.include?('tag.no_small_children')
    return nil
  end

  def pets
    return 'tag.pets_welcome' if self.property_details.include?('tag.pets_welcome')
    return 'tag.no_pets' if self.property_details.include?('tag.no_pets')
    return nil
  end

  def set_new_account_data
    self.set(:account_exchanges_made, self.account.exchanges_made)
    #:account_open_for_all_destinations
    self.set(:account_spoken_languages, self.account.profile.spoken_languages)
  end

  def set_account_data_on_listing
    #:account_expires_at
    self.set(:account_expires_at, self.account.current_subscription_expires_at.to_time)

    #:account_wish_lists
    wish_lists = []
    self.account.profile.wish_list_destinations.each do |wl|
      wish_lists.push({'location'=> wl.location, 'ne_lat' => wl.ne_lat, 'ne_lng' => wl.ne_lng, 'sw_lat' => wl.sw_lat, 'sw_lng' => wl.sw_lng, 'country_code' => wl.country_code, 'destination' => wl.destination})
    end
    self.set(:account_wish_lists, wish_lists)

    #:account_terminated
    self.set(:account_terminated, self.account.terminated)

    #:account_country_short
    self.set(:account_country_short, self.account.country_short)

    #:account_children
    self.set(:account_children, self.account.profile.number_of_children)

    #:account_adults
    self.set(:account_adults, self.account.profile.number_of_adults)

    #:account_pets
    self.set(:account_pets, self.account.profile.number_of_pets)
    self.set(:account_spoken_languages, self.account.profile.spoken_languages)
    self.set(:account_exchanges_made, self.account.exchanges_made)
    #:account_open_for_all_destinations
    self.set(:account_open_for_all_destinations, self.account.profile.open_for_all_destinations)
  end

  def concat_exchange_dates
    today = Date.today()
    start_date = nil
    end_date = today
    self.exchange_dates.where(:latest_date.gt => today).order_by(:earliest_date).each do |ed|
      start_date = ed.earliest_date if start_date.nil?
      if ed.latest_date > end_date
        end_date = ed.latest_date
      end
    end

    if start_date.nil?
      return nil
    end

    return "#{start_date.strftime("%b %d, %Y")} - #{end_date.strftime("%b %d, %Y")}"
  end

  ######## BETA TO CURRENT SYNC ############
  def set_legacy_main_photo
    #Remove old main photo.
    self.listing_images.delete_all(conditions: { :main_photo => true })

    filename = File.basename(self.main_photo.to_s)

    Listing.collection.update( { "_id" => self.id }, { '$addToSet' => {
      'listing_images' => { '_id' => BSON::ObjectId.from_time(Time.now.utc, :unique => true),
      'image' => filename,
      'caption' => self.main_photo_caption,
      'path' => self.main_photo_path,
      'category' => 'home',
      'publicly_visible' => true,
      'main_photo' => true,
      'created_at' => Time.now.utc,
      'updated_at' => Time.now.utc}
      }})
  end

  def set_path
    self.main_photo_path = "#{self.country_code.downcase}/#{self.listing_number.downcase}"
  end

  ##
  # Adds the uploaded main photo image to the set of listing images
  def add_main_photo_to_image_set
    filename = File.basename(self.main_photo.to_s)
    Listing.collection.update(
        { "_id" => self.id },
        {
            '$addToSet' => {
                'listing_images' => {
                    '_id' => BSON::ObjectId.from_time(Time.now.utc, :unique => true),
                    'image' => filename,
                    'caption' => self.main_photo_caption,
                    'path' => self.main_photo_path,
                    'category' => 'home',
                    'publicly_visible' => true,
                    'main_photo' => true,
                    'created_at' => Time.now.utc,
                    'updated_at' => Time.now.utc
                }
            }
        }
    )

    self.listing_images.where(main_photo: true).each do |image|
      image.update_attributes(main_photo: false, order: 1)
    end
  end

  ##
  # Sets the caption for main photo and image tagged as main photo
  def set_main_photo_caption(caption)
    self.set(:main_photo_caption, caption)
    self.listing_images.set_caption_main_photo(caption)
  end

  def correct_location
    list  = [google_formatted_address, lat, lng, location, country, country_code]
    list.each do |item|
      if item.blank? or item.nil?
        errors.add(:location, I18n.t('error.need_correct_address'))
        return
      end
    end
  end

  def correct_surroundings
    surroundings.each do |place|
      if place['name'].blank? or place['distance'].blank? or place['lat'].blank? or place['lng'].blank? or place['id'].blank?
        errors.add(:surroundings, I18n.t('error.missing_markers_name'))
        return
      end
      if place['name'].length > 30
        errors.add(:surroundings, I18n.t('error.name_invalid_number_characters'))
        return
      end
    end
  end

  def latest_date_must_be_higher_than_earliest
    return if earliest_date.blank? or latest_date.blank?
    if earliest_date > latest_date
      errors.add(:earliest_date, I18n.t('error.require_earlier_than_latest_date'))
    end
  end

  def add_listing_number_to_account
    self.account.push(:listing_numbers, self.listing_number)
  end

  def remove_listing_number_from_account
    self.account.pull(:listing_numbers, self.listing_number)
  end

  def set_last_updated
    self.set(:last_updated, Time.now)
  end

  def add_to_match_alert
    self.match_alert_expires = Time.now + 10.minutes
  end

  def update_listing_number(listing_number)
    old_number = self.listing_number
    self.listing_number = listing_number
    if self.save
      self.account.pull(:listing_numbers, old_number)
      self.account.push(:listing_numbers, listing_number)
    end
  end

  def set_map_visiblity(visibility)
    self.map_visibility = visibility
    self.save
  end

  def get_country
    Country.where(short: self.country_code).first
  end

  def is_valid_for_public
    listing_params = ActiveListing.get_validation_params(self)
    active_listing = ActiveListing.new(listing_params)

    return active_listing.valid?
  end

  def is_valid_and_has_future_dates
    if not self.has_future_exchange_dates
      return false
    end

    listing_params = ActiveListing.get_validation_params(self)
    active_listing = ActiveListing.new(listing_params)
    return active_listing.valid?
  end

  def is_expired
    account_expires_at < Date.today.to_time.utc
  end

  # Return progress fro how complete the account profile is
  def get_progress
    listing_params = ActiveListing.get_validation_params(self)

    ActiveListing.new(listing_params).progress
  end

  # Creates a new listing image document for an uploaded image file
  def create_listing_image(params)
    image = self.listing_images.create!(params)
    image.update_attributes(publicly_visible: false, category: 'home', caption: '')

    image
  end

  # Checks if the listing belongs to the current user.
  def belongs_to_user(user)
    user.account.id == self.account_id
  end

  # Updates the location for a listing
  def update_location(params)
    country_msgid = params[:listing][:country]
    country = Country.get_by_short(params[:listing][:country_code])

    if country
      country_msgid = country.msgid
    end

    loc = [params[:listing][:lat].to_f, params[:listing][:lng].to_f]
    self.update_attributes(
      lat: params[:listing][:lat],
      lng: params[:listing][:lng],
      street: params[:listing][:street],
      postal_town: params[:listing][:postal_town],
      postal_code: params[:listing][:postal_code],
      state: params[:listing][:state],
      state_long: params[:listing][:state_long],
      country: country_msgid,
      country_code: params[:listing][:country_code],
      google_formatted_address: params[:listing][:google_formatted_address],
      location: loc,
      location_reversed: loc.reverse
    )
  end

  ##
  # Enables the listing for public access for guests and members
  def enable_for_public
    # TODO Create and write all the checks necessary for the listing to become active and public
    self.update_attribute(:active, true)
  end

  # Enables the listing for public access for guests and members
  def set_availability_for_exchange(availability)
    # TODO Create and write all the checks necessary for the listing to become active and public
    self.update_attribute(:open_for_exchange, availability)

    # LEGACY make sure its set active when its open for exchange
    self.update_attribute(:active, true) if availability

    # Removed from hotlist if inactive
    if not self.open_for_exchange
      self.remove_from_hot_list()
    end
  end

  ##
  # Disables the listing for public access for guests and members
  def disable_for_public
    self.update_attribute(:active, false)
  end

  ##
  # Adds a listing to the hot list
  def mark_for_hot_list
    if self.is_available_for_hot_list
      return self.update_attribute(:added_to_hot_list, Time.now)
    end
    return false
  end

  ##
  # Removes a listing from the hot list
  def remove_from_hot_list
    self.update_attribute(:added_to_hot_list, nil)
  end

  ##
  # Checks to see if the listing is in the hot list or not.
  def is_in_hot_list
    if self.added_to_hot_list.nil?
      return false
    end

    if self.added_to_hot_list >= 4.days.ago.utc
      return true
    end

    return false
  end

  ##
  # Checks to see if the listing has an exchange date in the next comming 8 weeks.
  # If it does the listing is valid for the hot list
  # If not, the user can't add the listing to the hot list without creating an valid exchange date
  def is_available_for_hot_list
    weeks_from_now = 8.weeks.from_now.to_i
    now = Time.now.utc.to_i
    self.exchange_dates.each do |availability_date|
      if availability_date.earliest_date.to_i <= weeks_from_now and availability_date.latest_date.to_i > now and self.active == true
        return true
      end
    end

    return false
  end

  # Retursn tru if listing has future exchange dates
  def has_future_exchange_dates
    now = Time.now.utc.to_i
    self.exchange_dates.each do |availability_date|
      if availability_date.latest_date.to_i > now
        return true
      end
    end
    return false
  end

  def update_children_pets_settings(tags)
    # Make sure we only hav one of these
    limited_tags = ['tag.no_pets', 'tag.no_small_children', 'tag.pets_welcome', 'tag.children_welcome' ]

    self.pull_all(:property_details, limited_tags)
    self.add_to_set(:property_details, [ tags[:children], tags[:pets] ])
  end

  ##
  # Updates the property details with all property details that are set to true in the form
  def update_property_details(property_tags)
    # TODO Might be possible to remove and not needed if the surroundings and descriptions forms always are populated
    if property_tags.blank?
      return
    end

    property_details = self.property_details

    # Add the property details set to true
    property_tags.each do |tag, keep|
      if keep == "true"
        property_details.push(tag)
      end
    end

    # Remove all duplicate tags
    property_details = property_details.uniq
    # Remove nils
    property_details.delete_if {|tag| tag.nil?}

    # Remove the property details set to false
    property_tags.each do |tag, keep|
      if keep == "false"
        property_details.delete(tag)
      end
    end
    self.set(:property_details, property_details)
  end

  def update_property_settings(settings)
    self.property_type = settings[:property_type]
    self.environment = settings[:environment]
    self.sleeping_capacity = settings[:sleeping_capacity]
    self.bedrooms = settings[:bedrooms]
    self.bathrooms = settings[:bathrooms]
    self.floor = settings[:floor]
    self.living_area = settings[:living_area]
    self.living_area_unit = settings[:living_area_unit]
    self.total_area = settings[:total_area]
    self.total_area_unit = settings[:total_area_unit]
    self.bicycles = settings[:bicycles]

    self.save
  end

  ##
  # Updates the exchanges types with all exchange types that are set to true in the form
  def update_exchange_types(exchange_type_tags)
    exchange_types = self.exchange_types

    # Add the exchange types set to true
    exchange_type_tags.each do |tag, keep|
      if keep == "true"
        exchange_types.push(tag)
      end
    end

    # Remove all duplicate tags
    exchange_types = exchange_types.uniq

    # Remove the exchange types set to false
    exchange_type_tags.each do |tag, keep|
      if keep == "false"
        exchange_types.delete(tag)
      end
    end

    self.set(:exchange_types, exchange_types)
  end

  ##
  # Filters and returns the correct exchange types for the listing
  def get_exchange_types
    exchange_types = []
    ExchangeType.where(:selectable => true).each do |et|
      exchange_types.push(et.msgid)
    end

    if self.exchange_types.empty? or self.exchange_types.include?('exchangetype.open_for_all_offers')
      return exchange_types
    end

    return exchange_types & self.exchange_types
  end

  ##
  # Filters and returns an array of allowed property details
  def get_allowed_property_details
    allowed_property_details = []
    selectable_property_details = PropertyDetail.where(:selectable => true)
    selectable_property_details.each do |pd|
      allowed_property_details.push(pd[:msgid])
    end

    return allowed_property_details
  end

  def get_main_photo
    if self.main_photo.size_458.blank?
      # Need to test for 458 version as the imported photos do not
      # exists in 1024 size but the filename in the db is *-1024.jpg
      return nil
    end

    # Use Openstruct for dot notation
    h_photo = {:image => self.main_photo, :caption => self.main_photo_caption, :path => self.main_photo_path}
    return OpenStruct.new(h_photo)
  end

  def get_images_by_category(categories)
    self.listing_images.where(:category.in => categories).order_by([[:order, :asc]])
  end

  def get_images_by_all_categories()
    all_categories = ['home', 'lifestyle', 'family', 'surroundings']
    return self.listing_images.where(:category.in => all_categories).order_by([[:order, :asc]])
  end

  def create_statistics(request)
    begin
      user = request.env['warden'].authenticate(:scope => :user)
      listing_number = nil
      if user.nil?
        return
      end

      if user.account.id == self.account.id
        return
      end

      if user.account.has_listing?
        listing_number = user.account.listings.first.listing_number
      end
      country = Country.get_by_short(user.account.country_short)
      country_short = country.short
      country_msgid = country.msgid


      self.inc(:page_views, 1)

      self.statistics.create(
        user_type: user.nil? ? 'guest' : 'member',
        user_id: user.nil? ? nil : user.id,
        user_name: user.nil? ? nil : user.name,
        account_id: user.nil? ? nil : user.account.id,
        account_number: user.nil? ? nil : user.account.account_number,
        listing_number: listing_number,
        country_short: country_short,
        country_msgid: country_msgid,
        user_agent: request.env['HTTP_USER_AGENT'] ? request.env['HTTP_USER_AGENT'] : 'unknown',
        language: request.env['HTTP_ACCEPT_LANGUAGE'][0,2] ? request.env['HTTP_ACCEPT_LANGUAGE'][0,2] : 'unknown',
        charset: request.env['HTTP_ACCEPT_CHARSET'] ? request.env['HTTP_ACCEPT_CHARSET'] : 'unknown',
        ip_address: request.env['REMOTE_ADDR'] ? request.env['REMOTE_ADDR'] : 'unknown',
        count_date: Time.now.utc.strftime("%Y%m%d")
      )
    rescue
      # Log this somewhere
    end
  end

  def count_per_date(period=nil)
    criteria = {:listing_id => self.id}
    if period
      begin
        date = period.to_i.days.ago.utc
        criteria.merge!({:created_at => {'$gt' => date}})
      rescue
        criteria = {:listing_id => self.id}
      end
    end

    stats = ListingStatistic.collection.group(
      :cond => criteria,
      :key => 'count_date',
      :initial => {count: 0},
      :reduce => "function(doc, out) {out.count += 1;}"
    )

    stats = stats.sort_by{ |hsh| hsh['count_date'] }
    stats.each do |stat|
      stat['count_date'] = stat['count_date'][6..8] + "/" + stat['count_date'][4..5]  + line_break?(stats.count) +  stat['count_date'][0..3]
    end

    stats
  end

  def line_break?(count)
    return "<br/>" if count > 5
    "/"
  end

  def top_countries(limit=nil)
    stats = ListingStatistic.collection.group(
      :cond => {:listing_id => self.id, :user_type => 'member', :created_at => { '$gte' => (Time.now - 90.days).utc } },
      :key => 'country_short',
      :initial => {count: 0},
      :reduce => "function(doc, out) {out.count += 1; out.country_msgid = doc.country_msgid;}"
    )

    stats = stats.sort_by{ |hsh| hsh['count'] }.reverse
    stats = stats.first(limit) unless limit.nil?
    stats = stats.map { |foo| {'country_short'=>foo['country_short'], 'count' => foo['count'], 'country_msgid' => foo['country_msgid'], 'country_long' => I18n::t(foo['country_msgid'])} }
    return stats
  end

  def top_visitors(limit=nil)
    stats = ListingStatistic.collection.group(
      :cond => {:listing_id => self.id, :user_type => 'member', :created_at => { '$gte' => (Time.now - 90.days).utc } },
      :key => 'user_id',
      :initial => {count: 0},
      :reduce => "function(doc, out) {out.count += 1; out.account_number = doc.account_number; out.user_name = doc.user_name;}"
    )
    stats = stats.sort_by{ |hsh| hsh['count'] }.reverse
    stats = stats.first(limit) unless limit.nil?

    begin
      stats.each do |stat|
        account = Account.where(:account_number => stat['account_number'].to_i).first

        if account.nil? or account.listings.first.nil?
          stat['listing_id'] = nil
          stat['listing_number'] = nil
          if stat['user_name'].nil?
            stat['user_name'] = 'Guest'
          end
          next
        end

        stat['listing_id'] = account.listings.first.id
        stat['listing_number'] = account.listings.first.listing_number
      end
    rescue
      # Log this somewhere
    end

    return stats
  end



  def latest_visitors(limit=20, must_filter=false)

    criteria = ListingStatistic.where(listing_id: self.id, :user_type => 'member')
    stats = ListingStatistic.collection.db.command({ "aggregate" => "listing_statistics", "pipeline" => [
      {"$match"=>criteria.selector},
      {"$sort" => {"created_at" => -1}},
      {"$limit" => limit},
      {"$group" => { "_id" => {"account_number" => "$account_number", "user_name" => "$user_name"}, "created_at" => {"$push" => "$created_at"}}},
      {"$sort" => {"created_at" => -1}}
      ]})['result']

    begin
      stats.each do |stat|
        account_number = stat['_id']['account_number']
        stat['user_name'] = stat['_id']['user_name']
        account = Account.where(:account_number => account_number.to_i).first

        if account.nil? or account.listings.first.nil?
          next # Do not show people without listing
        end
        first_listing = account.listings.first

        stat['listing_id'] = first_listing.id
        stat['listing_image'] = first_listing.main_photo.size_60
        stat['listing_number'] = first_listing.listing_number
        stat['location'] = [first_listing.postal_town, I18n.t(first_listing.country)].join(', ')
      end
    rescue
      # Log this somewhere
    end
    must_filter ? stats.slice(0..19) : stats
  end

  ##
  # Used to filter out different sets of listing images
  def self.filter_images(image_set, category)
    filtered_images = []

    image_set.each do |image|
      if image.category == category
        filtered_images << image
      end
    end

    return filtered_images
  end

  def display_tags
    filter = ["tag.non_smoking", "tag.use_exchange_of_car", "tag.pet_care_wanted", "tag.no_pets", "tag.no_small_children", "tag.pets_welcome", "tag.children_welcome"]
    tags = self.property_details.select{ |tag| tag.in? filter }
    return tags
  end

  def rotate_main_photo direction
    main_photo.versions.each do |_, uploaded_version|
      main_photo = MiniMagick::Image.new(uploaded_version.path)
      begin
        main_photo.rotate direction == :left ? "-90" : "90"
      rescue => e
        Rails.logger.error("Could not rotate image #{uploaded_version.path}: #{e}")
      end
    end
  end

  # Scopes for listings
  class << self
    def active_account
      where(:account_terminated => false, :account_expires_at.gte => Date.today.to_time.utc)
    end

    def active_account_or_past_members
      where("$and" => [
          "$or" => [
            {:account_expires_at.gte => Date.today.to_time.utc},
            {open_past_listing: true},
          ]
      ])
    end

    def searchable
      ## This is for legacy purposes as the current system can have incomplete listings.
      ## We always set active = true in the BETA system anyways.
      where(:active => true)
      #where()
    end

    def not_searchable
      where(:active => false)
    end

    def is_open_for_exchange
      where(open_for_exchange: true, :open_past_listing.ne => true)
    end

    def with_outdated_exchange_dates
      any_of({:exchange_dates.matches => {:latest_date.lte => Time.now.utc }},
             {:exchange_dates.in => [[], nil]})
    end

    def has_permission(user)
      if user.nil? || user.has_role(:agent) || user.has_role(:admin)
        # return a where just to keep the method chaining
        return where
      end

      where(account_id: user.account_id)
    end

    # Returns a critera for listings that has a valid hot list date
    def in_hot_list
      where(:added_to_hot_list.gte => 4.days.ago.utc)
    end

    def available_for_hot_list
      weeks_from_now = 8.weeks.from_now.utc
      where(
        :exchange_dates.matches => {:earliest_date.lt => weeks_from_now }
      )
    end

    # Returns a listing based on the document listing id
    def get_by_id(listing_id)
      find(listing_id)
    end

    # Returns a listing based on both listing ID and an account id that is retrived from the current user.
    def get_account_listing(account_id, listing_id)
      where(account_id: account_id).find(listing_id)
    end

    def get_by_number(listing_number)
      first(conditions: {listing_number: listing_number})
    end

    ##
    # Used by the find by member name on the member dashboard landing page
    def find_by_listing_number(query)
      if query.blank?
        return {}
      end
      query = query.strip.upcase
      self.where(:listing_number => /^#{query}/).order_by([[:listing_number, :asc]]).limit(20)
    end

    def has_main_photo
      where(:main_photo => true)
    end

    def only_international(current_user)
      # codes related to French members
      # they can subscribe for national, international or both
      #
      # This method is used to offer only international listings
      not_allowed = ['BL', 'FR', 'GP', 'MC', 'MF', 'MQ', 'NC', 'PF', 'PM', 'RE', 'TF', 'WF', 'YT', 'GF']
      if current_user and not_allowed.include?(current_user.account.country_short)
        return where(:account_country_short.nin => not_allowed)
      end
      where()
    end

    def related(listing)
      where(:location_reversed => {
        "$near" => {
          "$geometry" => {
            "type" => "Point", "coordinates" => listing.location_reversed
          }
        }
      }).where(:_id.ne => listing.id, :country_code => listing.country_code, :sleeping_capacity.gte => listing.sleeping_capacity.to_i)
    end

    def add_bounds_padding(ne_lat, ne_lng, sw_lat, sw_lng)
      # This padding was added because we were having problems to
      # recognize other listings in the neighborhood.
      padding = 0.03

      # use padding to resize the rectangle. Increase the value for north
      # and decrease for south
      ne_lat = ne_lat.to_f + padding
      ne_lng = ne_lng.to_f + padding
      sw_lat = sw_lat.to_f - padding
      sw_lng = sw_lng.to_f - padding

      [ne_lat, ne_lng, sw_lat, sw_lng]
    end

    def within_bounds(ne_lat, ne_lng, sw_lat, sw_lng)
      ne_lat, ne_lng, sw_lat, sw_lng = add_bounds_padding(ne_lat, ne_lng, sw_lat, sw_lng)

      Rails.logger.debug(ne_lat)
      Rails.logger.debug(ne_lng)
      Rails.logger.debug(sw_lat)
      Rails.logger.debug(sw_lng)

      if ne_lng < sw_lng
        Rails.logger.error("Using weird condition with hard coded numbers at app/models/listing.rb#within_bounds")

        # Handle the dateline problem by splitting up the bounds in two.
        criteria1 = {:lat.lte => ne_lat, :lat.gte => sw_lat, :lng.lte => 180.0, :lng.gte => sw_lng}
        criteria2 = {:lat.lte => ne_lat, :lat.gte => sw_lat, :lng.lte => ne_lng, :lng.gte => -179.99}
        any_of( criteria1, criteria2 )
      else
        where(:lat.lte => ne_lat).where(:lat.gte => sw_lat).where(:lng.lte => ne_lng).where(:lng.gte => sw_lng)
      end
    end

    def within_dates(date_utc)
      where(:"exchange_dates.earliest_date".lte => date_utc).
        where(:"exchange_dates.latest_date".gte => date_utc)
    end

    def get_by_wish_list(lat, lng)
      where(
        :account_wish_lists.matches => {
          :ne_lat.gt => lat,
          :ne_lng.gt => lng,
          :sw_lat.lt => lat,
          :sw_lng.lt => lng
        }
      )
    end

    def get_by_wish_list_code(code)
      where(:"account_wish_lists.country_code" => code)
    end
  end

  protected

  # Adds a listing number to an already existing listing
  # Only used when creating new listings
  def create_listing_number
    return unless self.listing_number.nil?

    number = Counter.get_next
    self.listing_number = self.account.country_short.upcase + number.to_s
  end


  def validate_listing
    listing_params = ActiveListing.get_validation_params(self)
    active_listing = ActiveListing.new(listing_params)

    if not active_listing.valid?
      self.active = false
    end
    return true
  end

  def validate_searchable
    listing_params = SearchableListing.get_validation_params(self)
    searchable_listing = SearchableListing.new(listing_params)

    if not searchable_listing.valid?
      self.searchable = false
      return
    end
    self.searchable = true
  end

  default_scope where(account_terminated: false)
end
