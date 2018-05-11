module GeoAndLocaleSettings

  def geo_and_user_check
    # Unfortunately we will need to keep this code here.  It helps to use
    # staging.intervac.com.
    #
    # It should be done on the web server, but currently is not so simple to
    # add a new subdomain to intervac application. So we're considering the
    # staging server as a development one. It will good for what we need.
    #
    # FIXME: improve this whole geolocation thing.
    return create_or_update_cookie('en', 'www', 'se') if Rails.env.staging?

    #1 If the user is on a local computer, just set the locale, it is most likely a dev machine
    if is_local_host
      if cookies[:intervac_user].nil?
        I18n.locale = 'en'
        create_or_update_cookie('en', 'www', 'se')
        return
      end
      cookie_jar = CookieJar.get_cookie(cookies[:intervac_user])
      if cookie_jar
        country = Country.where(short: cookie_jar.country_short).first
        if country
          locale = set_locale(country, cookie_jar)
          create_or_update_cookie(locale, cookie_jar.country_subdomain, cookie_jar.country_short, cookie_jar)
          return
        end
      end
      # Reset cookie
      cookies[:intervac_user] = nil
      create_or_update_cookie('en', 'www', 'se')
      return
    end

    ## First check if we are on a valid country site
    if is_country_site()
      # Get country based on site
      subdomain = is_subdomain()

      if subdomain == 'uk'
        redirect_user_to_country_site('gb')
        return
      end

      country = Country.where(short: subdomain.upcase).first
      if country # Make sure we have country
        locale = set_locale(country)
        create_or_update_cookie(locale, subdomain, country.short)
        return
      end
    end

    ## We are now either on www or subdomain that do not have a own site

    ## Second check if we have a cookie
    if is_returning_user()
      cookie_jar = CookieJar.get_cookie(cookies[:intervac_user])
      if cookie_jar
        # Check if cookie has a country subdomain if so redirect
        subdomain = cookie_jar.country_subdomain
        if has_country_site(subdomain)
          redirect_user_to_country_site(subdomain)
          return
        end
        if is_subdomain() != 'www' # We should redirect to www if its not set correct? Should we show somewhere which country you are on?
          redirect_user_to_country_site('www')
        end
        country = Country.where(short: cookie_jar.country_short).first
        # Do we have a invalid cookie if we can't find country?
        if country
          set_locale(country, cookie_jar)
          return
        end
      end
      #Reset cookie
      cookies[:intervac_user] = nil
    end

    ## Third check ip location it is probably a new user so set locale to the countrys default locale
    country_short = get_country_short_from_ip(request.remote_ip)
    if country_short and has_country_site(country_short)
      redirect_user_to_country_site(country_short)
      return
    end

    ## Last just set locale to header locale
    if country_short
      country = Country.get_by_short_code(country_short)
      if country
        locale = set_locale(country)
        create_or_update_cookie( locale, 'www', country_short )
        ## Make sure we are on www
        if is_subdomain != 'www' # We should redirect to www if its not set correct? Should we show somewhere which country you are on?
          redirect_user_to_country_site('www')
        end
        return
      end
    end

    # Redirect to country chooser
    redirect_to_country_chooser
    return
  end

  def create_or_update_cookie(locale, subdomain, country_short, cookie_jar=nil)
    if cookie_jar.nil?
      cookie_jar = CookieJar.get_cookie(cookies[:intervac_user])
    end
    if cookie_jar.blank?
      uuid = get_new_uuid
      cookies.permanent[:intervac_user] = {:value => uuid, :domain => :all}
      # Use create or update?
      CookieJar.create!(uuid: uuid, locale: locale, country_subdomain: subdomain, country_short: country_short.upcase)
      return
    end
    cookie_jar.update_cookie(locale, subdomain, country_short)
  end

  ## Sets the locale
  def set_locale(country, cookie_jar=nil)
    if cookie_jar.nil?
      cookie_jar = CookieJar.get_cookie(cookies[:intervac_user])
    end
    if cookie_jar and country.has_locale(cookie_jar.locale)
      # Set locale to prefered locale if its allowed
      I18n.locale = cookie_jar.locale
      return cookie_jar.locale
    end
    header_locale = extract_locale_from_accept_language_header

    if country.has_locale(header_locale)
      # Set locale to header locale if its allowed
      I18n.locale = header_locale
      return header_locale
    end

    if country.default_locale # Use default locale if exist else use header_locale
      I18n.locale = country.default_locale
      return country.default_locale
    end
    # Fallback to en
    I18n.locale = 'en'
    return 'en'
  end

  ##
  # Gets the locale based on the users browser settings
  # IF not found use 'en'
  def extract_locale_from_accept_language_header
    begin
      locale = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first

      locales = {
        'de' => 'de_DE',
        'da' => 'da_DK',
        'dk' => 'da_DK',
        'fi' => 'fi_FI',
        'fr' => 'fr_FR',
        'de' => 'de_DE',
        'en' => 'en_GB',
        'uk' => 'en_GB',
        'us' => 'en_GB',
        'gr' => 'el_GR',
        'is' => 'is_IS',
        'it' => 'it_IT',
        'ja' => 'ja_JP',
        'nl' => 'nl_NL',
        'no' => 'no_NO',
        'pl' => 'pl_PL',
        'pt' => 'pt_PT',
        'ro' => 'ro_RO',
        'ru' => 'ru_RU',
        'es' => 'es_ES',
        'sv' => 'sv_SE',
        'se' => 'sv_SE'
      }

      if not locales.has_key?(locale)
        return "en"
      end

      return locales[locale]
    rescue
      return "en"
    end
  end

  ##
  # Check to see if the permanent cookies already exists and then guess that it is a returning user
  def is_returning_user
    if cookies[:intervac_user].nil?
      return false
    end
    return true
  end

  ##
  # Returns a country short code based on IP address or false if no country is found
  def get_country_short_from_ip(remote_ip)
    begin
      geoip = GeoIP.new("#{Rails.root}/lib/GeoIP.dat")
      country = geoip.country(remote_ip)

      if country != nil and country.country_code > 0
        short = translate_site(country.country_code2) # Se if we have a GB that should be UK
        return short
      end
    rescue
      return false
    end
    return false
  end

  ##
  # Checks if the user visits a country site
  def is_country_site

    subdomain = is_subdomain
    country_sites = Rails.application.config.country_sites

    if subdomain and country_sites.include?(subdomain.downcase)
      return true
    end

    return false
  end

  ##
  # Checks if there is a country site available for the user
  def has_country_site(subdomain)

    country_sites = Rails.application.config.country_sites

    if country_sites.include?(subdomain.downcase)
      return true
    end

    return false
  end

  ##
  # Check if the current requests accesses a subdomain
  def is_subdomain

    subdomains = request.subdomains
    subdomain = subdomains[0]

    if subdomain != nil
      return subdomain
    end

    return false
  end

  ##
  # Redirects the user to a country site
  def redirect_user_to_country_site(subdomain)
    redirect_to("http://#{subdomain}.#{Rails.application.config.main_domain}#{request.fullpath}")
    return
  end

  def redirect_to_country_chooser
    redirect_to("http://www.#{Rails.application.config.main_domain}/country/choose")
    return
  end

  ##
  # Translates the ISO code to the correct country site
  def translate_site(site)

    site = site.downcase
    sites = {
      'gb' => 'uk'
    }

    if not sites.has_key?(site)
      return site
    end

    return sites[site]
  end

  ##
  # checks is the ip belongs to a local computer
  def is_local_host
    require 'ipaddr'
    begin
      local = IPAddr.new("127.0.0.0/8")
      private1 = IPAddr.new("10.0.0.0/8")
      private2 = IPAddr.new("172.16.0.0/12")
      private3 = IPAddr.new("192.168.0.0/16")
      private4 = IPAddr.new("85.230.85.45")
      private5 = IPAddr.new("94.234.170.18")

      if local.include?(request.remote_ip)
        return true
      end
      if private1.include?(request.remote_ip)
        return true
      end
      if private2.include?(request.remote_ip)
        return true
      end
      if private3.include?(request.remote_ip)
        return true
      end
      if private4.include?(request.remote_ip)
        return true
      end
      if private5.include?(request.remote_ip)
        return true
      end
      return false
    rescue
      return false
    end
  end

  ##
  # Generates and returns a new UUID
  def get_new_uuid
    uuid = UUID.new
    return uuid.generate
  end
end
