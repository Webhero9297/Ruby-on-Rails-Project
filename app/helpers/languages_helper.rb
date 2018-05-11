module LanguagesHelper
  include GeoAndLocaleSettings

  def languages_for_country
    cookie_jar = CookieJar.get_cookie(cookies[:intervac_user])
    if cookie_jar.nil?
      return content_tag('li', link_to(t('language.english'), change_language_url('en'), class: 'language-menu-link'))
    end
    country_short = cookie_jar.country_short
    
    country = Country.where(short: country_short.upcase).first
    if country.nil?
      return content_tag('li', link_to(t('language.english'), change_language_url('en'), class: 'language-menu-link'))
    end
    
    if country.locales.empty? then
      return content_tag('li', link_to(t('language.english'), change_language_url('en'), class: 'language-menu-link'))
    end
    languages = ''
    
    country.locales.each do |locale|
      if locale['locale'] then
        if 'nl_BE' == locale['locale']
          languages +=  content_tag('li', link_to(t('language.nederlands_be', locale: locale['locale']), change_language_url(locale['locale']), class: 'language-menu-link'))
        else
          languages +=  content_tag('li', link_to(t(locale['msgid'], locale: locale['locale']), change_language_url(locale['locale']), class: 'language-menu-link'))
        end
      end
    end
    return raw(languages)
  end
end
