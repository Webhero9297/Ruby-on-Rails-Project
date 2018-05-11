# encoding: utf-8
class Country
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  embeds_one  :merchant_information, :class_name => 'MerchantInformation', validate: false
  embeds_many :price_plans, :class_name => 'PricePlan'

  field :msgid,                               type: String
  field :short,                               type: String
  field :continent,                           type: String
  field :currency,                            type: String
  field :regions,                             type: Array, default: []
  field :prioritized,                         type: Boolean, default: false
  field :locales,                             type: Array, default: [{msgid: 'language.english', locale: 'en'}]
  field :lat,                                 type: Float, default: 0.0
  field :lng,                                 type: Float, default: 0.0
  field :paypal_email,                        type: String, default: ''
  field :default_locale,                      type: String, default: 'en'
  field :calling_code,                        type: String, default: '00'
  field :kind,                                type: String, default: 'oc' #vip or oc
  field :offline_payment_text,                type: String, default: ''
  field :allow_direct_access,                 type: Boolean, default: true
  field :ne_lat,                              type: Float, default: 0.0
  field :ne_lng,                              type: Float, default: 0.0
  field :sw_lat,                              type: Float, default: 0.0
  field :sw_lng,                              type: Float, default: 0.0
  field :accept_paypal,                       type: Boolean, default: true
  field :accept_paypal_text,                  type: String, default: ''
  field :accept_invoice,                      type: Boolean, default: false
  field :accept_invoice_text,                 type: String, default: ''
  field :accept_sage_pay,                     type: Boolean, default: false
  field :accept_sage_pay_text,                type: String, default: ''
  field :accept_av_solutions,                 type: Boolean, default: false
  field :accept_av_solutions_text,            type: String, default: ''
  field :accept_generic_offline,              type: Boolean, default: false
  field :accept_generic_offline_text,         type: String, default: ''
  field :accept_generic_offline_payment_info, type: String, default: ''
  field :accept_generic_offline_button_text,  type: String, default: ''
  field :total_members,                       type: Integer, default: 0
  field :active_members,                      type: Integer, default: 0
  field :trial_members,                       type: Integer, default: 0
  #field :accept_bank_transfer        type: Boolean, default: false
  #field :accept_bank_transfer_text   type: String, default: ''
  #field :accept_bank_check           type: Boolean, default: false
  #field :accept_bank_check_text      type: String, default: ''

  #validates :paypal_email, :format => { :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i }

  def self.check_if_promotion_code_is_valid(promotion_code)
    # To make sure the promotion case is uppercase
    promotion_code = promotion_code.upcase

    # Fetches the country who has a price plan with the promotion code
    country = self.where(:"price_plans.promotion_codes.code" => promotion_code).first

    # If no country has a price plan with the promotion code then exit and return false
    if country.nil?
      return false
    end

    # Fetches the actual embedded promotion code document
    code = country.price_plans.where(:"promotion_codes.code" => promotion_code).first.promotion_codes.where(:code => promotion_code).first

    # Checks if the promotion code has expired or has any usage left, if not then exit and return false
    if code.has_expired or not code.has_usage or code.archived
      return false
    end

    # Everything should be fine and the promotion code should be valid
    return true
  end

  def validate_promotion_code(promotion_code)
    # To make sure the promotion case is uppercase
    promotion_code = promotion_code.upcase
    # Fetches the actual embedded promotion code document
    price_plan = self.price_plans.where(:"promotion_codes.code" => promotion_code).first
    if price_plan.nil?
      return false
    end
    code = price_plan.promotion_codes.where(:code => promotion_code).first
    if code.nil? or code.has_expired or not code.has_usage
      return false
    end

    return true
  end

  # TODO write comment and change to a better method name
  def self.get_assigned_countries(short_codes)
    assigned_countries = self.any_in(short: short_codes)
    return assigned_countries
  end

  def has_locale(locale)
    self.locales.each do |l|
      if l['locale'] == locale then
        return true
      end
    end
    return false
  end

  def get_agents
    agents = User.agent_profile.to_a
    agents_for_country = []
    agents.each do |agent|
      agent.agent_profile.agent_for.each do |agent_country|
        if agent_country['short'] == self.short
          agents_for_country.push(agent)
        end
      end
    end
    return agents_for_country
  end

  def get_locales
    locales = []
    self.locales.each do |l|
      locales.push(l['locale'])
    end
    return locales
  end

  def self.get_msgid_for_locale(locale)
    country = Country.where(:"locales.locale" => locale).first
    if country
      country.locales.each do |l|
        if l['locale'] == locale then
          return l['msgid']
        end
      end
    end
  end

  def add_locale(locale, msgid)
    return if self.has_locale(locale)
    self.locales.push({'msgid' => msgid, 'locale' => locale})
    self.save!(validate: false)
  end

  def remove_locale(locale)
    self.locales.delete_if do |item|
      item['locale'] == locale
    end
    self.save
  end

  def self.remove_locale(locale)
    countries = Country.where(:"locales.locale" => locale)
    countries.each do |c|
      c.remove_locale(locale)
    end
  end

  def self.get_by_short(short)
    Country.where(short: short.upcase).first
  end

  # Returns an array of all countries sorted by the current users locale
  def self.sorted_by_language
    sorted_countries = []
    default_countries = []
    prioritized_countries = []
    divider = [['----------------------', 'nil']]
    countries = self.only(:msgid, :short, :prioritized, :kind).limit(300).to_a

    countries.each do |country|
      if country.kind == 'vip'
        prioritized_countries.push([ I18n.t(country.msgid), country.short])
      end
    end

    default_countries = countries.collect {|c| [ I18n.t(c.msgid), c.short ] }
    sorted_countries = prioritized_countries.sort + divider + default_countries.sort

    return sorted_countries
  end

  ##
  # Returns a 2d array sorted on translated msgid. First item contains the transalted msgid, the second item contains a hash with transalted msgid, country short code and continent.
  def self.sorted_array_hash
    sorted_countries = Hash.new
    countries = self.only(:msgid, :short, :continent).limit(300).to_a

    countries.each do |c|
      sorted_countries[I18n.t(c.msgid)] = {"msgid" => I18n.t(c.msgid), "short" => c.short, "continent" => c.continent }
    end

    return sorted_countries.sort_by { |k| k }
  end

  def self.get_shorts_as_array(kind=false)
    shorts = []
    if not kind
      countries = self.all
    else
      countries = self.where(kind: kind)
    end

    countries.each do |country|
      shorts.push(country.short)
    end

    return shorts
  end

  def self.get_default_price_plan(country_short)
    country = self.where(short: country_short.upcase).first
    if country.nil?
      return nil
    end
    price_plan = country.price_plans.where(default: true).first
    return price_plan
  end

  def self.get_trial_plan_for_country(country_short)
    country = self.where(short: country_short.upcase).first
    if country.nil?
      return nil
    end
    price_plan = country.price_plans.where(:kind => 'free').first
    return price_plan
  end

  def self.get_paid_plans_for_country(country_short)
    price_plan = Country.where(:short => country_short.upcase).first.price_plans.where(:kind => 'paid', :active => true)
    return price_plan
  end

  def self.get_last_active_plan(country_short)
    country = Country.where(:short => country_short.upcase).first
    return unless country
    country.price_plans.where(:active => true).last
  end

  def self.get_price_plan_by_country_and_id(country_short, price_plan_id)
    where(short: country_short.upcase).first.price_plans.find(price_plan_id)
  rescue Mongoid::Errors::DocumentNotFound
    nil
  end

  def self.get_price_plan_by_country_and_promotion_code(country_short, promotion_code)
    price_plan = self.where(short: country_short.upcase).first.price_plans.where(:"promotion_codes.code" => promotion_code).first
    return price_plan
  end

  def self.get_by_promotion_code(promotion_code)
    promotion_code = promotion_code.upcase
    country = self.where(:"price_plans.promotion_codes.code" => promotion_code).first
    return country
  end

  def get_price_plan_by_promotion_code(promotion_code)
    promotion_code = promotion_code.upcase
    price_plan = self.price_plans.where(:"promotion_codes.code" => promotion_code).first
    return price_plan
  end

  def self.countries_with_agents
    agents = User.agent_profile.to_a
    country_agents = {}
    agents_for_country = []

    self.all.each do |country|

      agents.each do |agent|
        agent.agent_profile.agent_for.each do |agent_country|
          if agent_country['short'] == country.short
            agents_for_country.push(agent)
          end
        end
        country_agents[country.short] = {'agents' => agents_for_country}

      end
      agents_for_country = []
    end

    return country_agents
  end

  def members_count
    Account.where(:country_short => self.short).count
  end

  def members_active_count
    Account.where(:country_short => self.short).where(:subscriptions.matches => {:active => true, :expires_at.gt => Time.now.utc, :kind => 'paid'}).count
  end

  def members_trial_count
    Account.where(:country_short => self.short).where(:subscriptions.matches => {:active => true, :expires_at.gt => Time.now.utc, :kind => 'free'}).count
  end

  def member_stats
    all = self.member_count()
    active = self.members_active_count()
    trial = self.members_trial_count()
    stats = {:all => all, :active => active, :expired => (all-active), :trial => trial}
    return stats
  end

  ##
  # Sets the offline payment text for money checks and whatever
  def set_offline_payment_text(information_text)
    self.set(:offline_payment_text, information_text)
  end

  ##
  # Sets a boolean if country members can use and access their account directly or have to wait until payment has been registered.
  def set_allow_direct_access(allow)
    self.set(:allow_direct_access, allow)
  end

  ##
  # Scopes data mapper style. Methods that returns criteria can be treated as chainable scopes as well.
  class << self
    def get_by_short_code(country_short)
      first(conditions: {short: country_short.upcase})
    end

    def prioritized
      where(prioritized: true)
    end
  end
end
