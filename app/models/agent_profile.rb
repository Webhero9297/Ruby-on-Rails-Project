class AgentProfile
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  embedded_in :user, :class_name => 'User'
  embeds_one :profile_image, :class_name => 'AgentImage'
  accepts_nested_attributes_for :profile_image

  field :name,           type: String, default: ''
  field :address,        type: String, default: ''
  field :postal_town,    type: String, default: ''
  field :postal_code,    type: String, default: ''
  field :country,        type: String, default: ''
  field :telephone,      type: String, default: ''
  field :mobile,         type: String, default: ''
  field :fax,            type: String, default: ''
  field :email,          type: String, default: ''
  field :skype,          type: String, default: ''
  field :website,        type: String, default: ''
  field :office_hours,   type: String, default: ''
  field :video,          type: String, default: ''
  field :agent_for,      type: Array, default: [] # {short, msgid, locales}
  field :position,       type: Integer, default: 0
  field :active_members, type: Integer, default: 0


  ##
  # Returns a collection of countries assigned to the Agent
  def get_assigned_countries

    short_codes = self.get_assigned_countries_short_codes
    countries = Country.where(:short.in => short_codes).sort_by {|c| I18n.t(c.msgid) }

    return countries
  end

  def get_awaiting_access_accounts

    short_codes = self.get_assigned_countries_short_codes
    accounts = Account.where(:country_short.in => short_codes).and(:awaiting_access => true)

    return accounts
  end

  def calculate_total_active_members
    short_codes = self.get_assigned_countries_short_codes
    return 0 if short_codes.empty?
    Account.where(:country_short.in => short_codes).where(:subscriptions.matches => {:active => true, :expires_at.gt => Time.now.utc, :kind => 'paid'}).count
  end


  def reload_locales
    self.agent_for.each do |agent_country|
      country = Country.get_by_short(agent_country['short'])
      next if country.nil?
      agent_country['locales'] = country.get_locales
    end
    self.save
  end

  ##
  # Returns an array of country ISO short codes that an agent is assigned to
  def get_assigned_countries_short_codes

    countries = []

    self.agent_for.each do |country|
      countries.push(country['short'])
    end

    return countries
  end


  def locales
    all_locales = []
    for country in agent_for
      all_locales.concat(country['locales'])
    end
    all_locales.delete('en')
    all_locales
  end


  def assign_country(country)

    assigned = self.agent_for.detect {|f| f["short"] == country.short}

    if assigned then
      return false
    end

    self.push(:agent_for, {msgid: country.msgid, short: country.short, locales: country.get_locales})
  end
end
