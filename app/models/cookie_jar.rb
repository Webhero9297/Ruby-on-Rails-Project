class CookieJar
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  
  field :uuid,               type: String
  field :locale,             type: String
  field :country_subdomain,  type: String
  field :country_short,      type: String
  
  
  def self.get_cookie(uuid)
    cookie_jar = self.first(conditions: {uuid: uuid})
    return cookie_jar
  end
  
  
  def self.country_short(uuid)
    cookie_jar = self.get_cookie(uuid)
    return cookie_jar.country_short
  end
  
  
  def self.country_subdomain(uuid)
    cookie_jar = self.get_cookie(uuid)
    return cookie_jar.country_subdomain
  end
  
  
  def self.locale(uuid)
    cookie_jar = self.get_cookie(uuid)
    return cookie_jar.locale
  end
  
  def update_cookie(locale, subdomain, country_short)
    self.update_attributes(locale: locale, country_subdomain: subdomain, country_short: country_short.upcase)
  end
  
end
