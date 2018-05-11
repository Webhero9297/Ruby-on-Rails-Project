# encoding: UTF-8
module MongoI18nBackend
  class Store
    attr_reader :collection

    def initialize(collection, options={})
      @collection, @options = collection, options
    end

    def []=(key, value, options = {})
      Translations.create(_id: key, value: value)
    end

    # alias for read
    def [](key, options=nil)
      if doc = Translations.where(:_id => key.to_s).first
        doc["value"]
      end
    end

    def keys
      keys = []
      Translations.all.each do |row|
        keys.push(row["_id"])
      end
      keys
    end

    def del(key)
      Translations.where(:_id => key).delete_all
    end

    # Thankfully borrowed from Jodosha's redis-store
    # https://github.com/jodosha/redis-store/blob/master/lib/i18n/backend/redis.rb
    def available_locales
      Translations.all.distinct(:locale)
    end
  end
end