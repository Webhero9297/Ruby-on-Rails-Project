# encoding: UTF-8
class Translations
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection

  field :_id,                 type: String
  field :value,               type: String, default: nil
  field :locale,              type: String
  field :msgid,               type: String
  field :category,            type: String, default: 'other'
  field :limit,               type: Integer
  field :cloned_from,         type: String, default: nil
  field :cloned_changed,      type: Boolean, default: false
  field :field_codes,         type: String, default: ''
  field :origin_has_changed,  type: Boolean, default: false

  index :_id, unique: true
  index :locale
  index :category
  index([[ :locale, Mongo::ASCENDING], [ :msgid, Mongo::ASCENDING]], unique: true)

  scope :default_language, where(locale: "en")

  validates_presence_of :_id, :msgid, :locale
  validates_uniqueness_of :_id
  validates_uniqueness_of :msgid, :scope => :locale, :message => "Msgid is already taken. Either choose a new msgid or update your templates with the existing msgid."

  after_save :update_hammer
  # Make sure the value is JSON encoded before save
  # Disbaled as we got double escaping if we were just changing category
  #before_save :encode_value

  def self.store_translation(locale, key, value, category, field_codes)
    id = "#{locale}.#{key}"
    value = nil if value.blank?
    value = ActiveSupport::JSON.encode(value) unless value.is_a?(Symbol) or value.nil?
    Translations.create(_id: id, value: value, locale: locale, msgid: key, category: category, field_codes: field_codes)
  end

  def get_value
    unless self.value.is_a?(Symbol) or self.value.nil?
      begin
        ActiveSupport::JSON.decode(self.value)
      rescue Yajl::ParseError, MultiJson::ParseError
        # Please refer to #2770
        #
        # For some reason we expect the translation to be a JSON and have
        # double quotes. Currently we have both types.  It was the simplest
        # solution to implement given the current translation model and current
        # translations. We should take the change to fix that when migrating.
        ActiveSupport::JSON.decode(%Q{"#{self.value}"})
      end
    end
  end

  def self.add_default_translation(default_locale, key, value, category = 'other', field_codes = '')
    # First store default locale
    default_trans = Translations.store_translation(default_locale, key, value, category, field_codes)

    # Get all locales
    locales = Translations.available_locales
    locales.delete(default_locale)
    locales.each do |locale|
      new_trans = Translations.store_translation(locale, key, nil, category, field_codes)
      # If the locale is a clone
      if Translations.is_cloned?(locale)
        # Get a current translation to check the cloned from
        current = Translations.where(locale: locale, :cloned_from.ne => nil ).first
        next if current.nil?
        new_trans.origin_has_changed = true # This makes the translations show up in the special tab

        lang = current.cloned_from.split('.')[0]
        # DISABLED: We thought that the agent should see that there are new texts. If they want the en translation they can update themselves.
        # ENABLED AGAIN
        if lang == default_locale
          new_trans.value = default_trans.value
          new_trans.cloned_from = default_trans.id
          new_trans.save
          next
        end
        new_trans.cloned_from = "#{lang}.#{key}"
        new_trans.save
      end
    end
  end

  def self.is_cloned?(locale)
    Translations.exists?(conditions: { locale: locale, :cloned_from.ne => nil })
  end

  def self.clone_locale(from_locale, to_locale)
    # Make sure to_locale do not exists and that is 5 chars long
    to = self.get_translations_for_locale(to_locale)
    return if to.count > 0 or to_locale.length != 5
    current = self.get_translations_for_locale(from_locale)
    current.each do |t|
      new_trans = self.store_translation(to_locale, t.msgid, t.get_value, t.category, t.field_codes)
      new_trans.cloned_from = t.id
      new_trans.save
    end
  end

  def self.create_locale(locale)
    # Creates a brand new locale not based on anything else. (do need to use some info from default)
    existing = self.get_translations_for_locale(locale)
    return if existing.count > 0 or locale.length != 5
    current = self.get_default_translations()
    current.each do |t|
      new_trans = self.store_translation(locale, t.msgid, nil, t.category, t.field_codes)
    end
  end

  def self.update_cloned_locale(locale)
    # First update any new texts
    current = self.get_translations_for_locale(locale)
    c = 0
    original = nil
    current.each do |t|
      next if t.cloned_changed == true or t.cloned_from.nil?
      original = Translations.find(t.cloned_from)
      # Do not use update_translation as that resets cloned_from
      t.update_attribute(:value, original.value)
      c += 1
    end

    return c
  end

  def update_translation(value)
    value = nil if value.blank?
    value = ActiveSupport::JSON.encode(value) unless value.is_a?(Symbol) or value.nil?
    self.update_attribute(:value, value)
    self.update_attribute(:origin_has_changed, false)
    # Set that original test has changed
    if self.locale == "en"
      Translations.where(:msgid => msgid, :locale.ne => "en").update_all( origin_has_changed: true )
    end
    # See if we have any clones to update
    clones = Translations.where(:cloned_from => self.id)
    clones.each do |clone|
      next if clone.cloned_changed == true
      clone.update_attribute(:value, value)
    end
    return if self.cloned_from.nil?
    # If this is a clone set changed to true
    self.update_attribute(:cloned_changed, true)
  end

  def update_category(category)
    # Get all locales
    translations = Translations.where(msgid: self.msgid)
    translations.each do |t|
      t.update_attribute(:category, category)
    end
  end

  def update_field_codes(field_codes)
    # Get all locales
    translations = Translations.where(msgid: self.msgid)
    translations.each do |t|
      t.update_attribute(:field_codes, field_codes)
    end
  end

  def self.search(term, locale, only_missing=false)
    # Converting multibyte chars to codepoints
    escaped_term = term.unpack('U*').map{ |i|
      if i > 127
        "\\\\u" + i.to_s(16).rjust(4, '0')
      else
        [i].pack("U*")
      end
    }.join
    escaped_term = escaped_term.gsub('"', '\\\\\"')
    # WHen searching missing we search on the default locale
    trans = Translations.any_of({msgid: /#{term}/i}, {value: /#{escaped_term}/i}).where(locale: 'en')
    if locale == 'en'
      return trans
    end

    msg_ids = []
    trans.each do |a|
      msg_ids.push(a.msgid)
    end


    if only_missing
      return [] if msg_ids.empty?
      boo = Translations.any_in(:msgid => msg_ids).where(locale: locale).where(value: nil)
      return boo
    end

    trans = Translations.any_of({msgid: /#{term}/i}, {value: /#{escaped_term}/i}).where(locale: locale)

    trans.each do |a|
      msg_ids.push(a.msgid)
    end

    return [] if msg_ids.empty?
    msg_ids.uniq!

    boo = Translations.any_in(:msgid => msg_ids).where(locale: locale)
    return boo

  end


  def self.msgid_search(term, locale)
    Translations.where(msgid: /^#{term}/i).where(locale: locale)
  end

  def self.exists(msgid)
    if Translations.where(msgid: msgid, locale: 'en').first.nil?
      return false
    end
    return true
  end

  def self.get_default_translations
    Translations.get_translations_for_locale('en')
  end

  def self.get_translations_for_locale(locale)
    Translations.where(locale: locale).order_by([:msgid, :asc]).all
  end

  def self.get_missing_translations_for_locale(locale)
    Translations.where(locale: locale, value: nil).order_by([:msgid, :asc]).all
  end

  def self.count_missing_translations(locale)
    return Translations.where(locale: locale, value: nil).count
  end

  def self.get_changed_translations_for_locale(locale)
    Translations.where(locale: locale, origin_has_changed: true).order_by([:msgid, :asc]).all
  end

  def self.get_translations_for_locale_and_category(locale, category)
    Translations.where(locale: locale, category: category).order_by([:msgid, :asc]).all
  end

  def self.get_statistics_for_locale(locale)
    translations = Translations.get_translations_for_locale(locale)
    total = translations.count
    return nil if total == 0
    missing = translations.where(value: nil).count
    return {:locale => locale, :total => total, :missing => missing}
  end

  def set_category(category)
    Translations.where(msgid: self.msgid).update_all(category: category)
  end

  def self.get_categories
    #Filtering with default locale
    # FIX Mongoid DISTINCT do not work with order by so doing it ourselves
    Translations.where(locale: 'en').asc(:category).map {|i| i.category}.uniq
  end

  def self.get_statistics_for_locale_and_category(locale, category)
    translations = Translations.get_translations_for_locale_and_category(locale, category)
    total = translations.count
    missing = translations.where(value: nil).count
    return {:locale => locale, :total => total, :missing => missing, :category => category}
  end


  def self.available_locales
    Translations.all.distinct(:locale)
  end

  def self.delete_locale(locale)
    Translations.where(locale: locale).delete_all
  end

  protected

  def encode_value
    self.value = nil if self.value.blank?
    self.value = ActiveSupport::JSON.encode(self.value) unless self.value.is_a?(Symbol) or self.value.nil?
  end

  private

  def update_hammer
    HAMMER[self._id] = self.value unless value.nil?
  end
end
