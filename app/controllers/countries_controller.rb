# encoding: UTF-8
class CountriesController < ApplicationController
  include GeoAndLocaleSettings

  filter_access_to [:index, :price_plans, :awaiting]
  layout 'application'

  skip_before_filter :geo_and_user_check, :only => [:choose, :change]

  ##
  # Lists all the avialble countries for agents and admins
  def index
    if admin_session?
      @countries = Country.all.order_by([[:msgid, :asc]])
      @agent_countries = Country.where(kind: 'vip').order_by([[:msgid, :asc]])
    elsif agent_session?
      @countries = current_user.agent_profile.get_assigned_countries()
    else
      @countries = []
    end

    respond_to do |format|
      format.html {render(layout: 'management')}
    end
  end

  def show
    if admin_session?
      @countries = Country.all.order_by([[:msgid, :asc]])
      @agent_countries = Country.where(kind: 'vip').order_by([[:msgid, :asc]])
    elsif agent_session?
      @countries = current_user.agent_profile.get_assigned_countries()
    else
      @countries = []
    end

    @country = Country.find(params[:id])
    @agents = User.get_agent_profiles_for_country(@country.short)
    @accounts = Account.where(country_short: @country.short)
    locales = Translations.available_locales
    rets = {}
    locales.each do |locale|
      short = locale.split('_')[0]
      row = Language.where(short:  short).first
      if row
        msgid = row.msgid
        rets[locale]=msgid
      end
    end
    @locales = rets

    respond_to do |format|
      format.html {render(layout: 'management')}
    end
  end


  def price_plans
    @countries = current_user.agent_profile.get_assigned_countries

    respond_to do |format|
      format.html {render(layout: 'management')}
    end
  end

  def try_to_set_locale
    cookie_jar = CookieJar.get_cookie(cookies[:intervac_user])
    if cookie_jar and cookie_jar.locale
      # Set locale to prefered locale if its allowed
      I18n.locale = cookie_jar.locale
      return cookie_jar.locale
    end
    # Fallback to en
    I18n.locale = 'en'
    return 'en'
  end

  def choose
    try_to_set_locale
    session[:return_url] = price_plans_path

    @countries = Country.sorted_array_hash
    respond_to do |format|
      format.html
    end
  end

  def change
    locale = 'en'
    country_subdomain = 'www'
    country = Country.get_by_short_code(params[:short])
    uuid = cookies[:intervac_user]

    if has_country_site(country.short)
      country_subdomain = country.short
    end

    if not country.locales.empty?
      locale = country.default_locale
    end

    my_cookie = CookieJar.get_cookie(uuid)
    if my_cookie
      my_cookie.update_cookie(locale, country_subdomain.downcase, country.short)
    end

    return_url = "http://#{country_subdomain}.#{Rails.application.config.main_domain}#{session[:return_url]}"
    session[:return_url] = nil

    respond_to do |format|
      format.html {redirect_to(return_url)}
    end
  end

  def update
    @country = Country.find(params[:id])
    respond_to do |format|
      if @country.update_attributes(country_params)
        format.json { respond_with_bip(@country) }
      else
        format.json { respond_with_bip(@country) }
      end
    end
  end

  def edit_currency
    @country = Country.find(params[:id])

    respond_to do |format|
      format.html
      format.js
    end
  end

  def save_currency
    @country = Country.find(params[:id])
    @country.update_attribute(:currency, params[:country][:currency])

    respond_to do |format|
      format.html {redirect_to(country_price_plans_url(@country)) }
      format.js
    end
  end

  def edit_default_locale
    @country = Country.find(params[:id])

    respond_to do |format|
      format.js
    end
  end

  def save_default_locale
    @country = Country.find(params[:id])
    @country.update_attribute(:default_locale, params[:country][:default_locale])

    respond_to do |format|
      format.js
    end
  end

  def edit_kind
    @country = Country.find(params[:id])
    @kinds = {'OC' => 'oc', 'Agent country' => 'vip'}
    respond_to do |format|
      format.js
    end
  end

  def save_kind
    @country = Country.find(params[:id])
    @country.update_attribute(:kind, params[:country][:kind])

    respond_to do |format|
      format.js
    end
  end

  def save_available_locales
    @country = Country.find(params[:id])
    locales = params[:locales]
    current = []
    locales.each do |locale, dict|
      if dict['locale']
        current.push({'msgid' => dict['msgid'], 'locale' => locale})
      end
    end
    if current.length > 0
      @country.set(:locales, current)
      @country.save!(validate: false)
      # Make sure default locale is among locales
      default = @country.default_locale
      if not @country.has_locale(default)
        @country.set(:default_locale, current.first['locale'])
        @country.save!(validate: false)
      end
      @country.get_agents.each do |user|
        user.agent_profile.reload_locales()
      end
    end

    respond_to do |format|
      format.html {redirect_to(country_path(@country)) }
    end
  end

  ##
  # Lists all accounts that are waiting for activation for a single country
  def awaiting_access

    @country = Country.find(params[:id])
    @accounts = Account.where(:country_short => @country.short).and(:awaiting_access => true)

    respond_to do |format|
      format.html {render(layout: 'management')}
    end
  end

  private

  def country_params
    params.require(:country).permit(:paypal_email)
  end
end
