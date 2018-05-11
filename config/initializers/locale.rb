HAMMER = Hammerspace.new("/tmp/hammerspace")
hammer_backend = I18n::Backend::KeyValue.new(HAMMER)
 
collection = Translations.collection
mongo_backend = I18n::Backend::KeyValue.new(MongoI18nBackend::Store.new(collection))
 
I18n.backend = I18n::Backend::Chain.new(hammer_backend, mongo_backend, I18n.backend)
 
I18n.default_locale = :en
 
old_handler = I18n.exception_handler
I18n.exception_handler = lambda do |exception, locale, key, options|
  case exception
  when I18n::MissingTranslation
    #Rails.logger.debug ">> MISSING TRANSLATION FOR #{key} ON LOCALE #{locale} <<"
    return key
  when I18n::MissingTranslationData
    #Rails.logger.debug ">> MISSING TRANSLATION DATA FOR #{key} ON LOCALE #{locale} <<"
    return key
  else
    old_handler.call(exception, locale, key, options)
  end
end