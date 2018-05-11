namespace :maintenance do
  desc "fix searches"
  task :country_code_searches => :environment do
    accounts = Account.where(:searches.exists => true).where(:searches.not => {"$size" => 0})
    counter  = 0
    puts accounts.count
    accounts.each do |account|
      account.searches.each do |search|
        if search.q == 'Europe' or not search.country_code.blank?
          next
        end
        #country = Country.where(:ne_lat.gte => search.lat).where(:sw_lat.lte => search.lat).where(:ne_lng.gte => search.lng).where(:sw_lng.lte => search.lng).first
        country = Country.near(location: [search.lng, search.lat]).first
        if country
          search.set(:country_code, country.short)
          if search.q.blank?
            search.set(:q, t(country.msgid) )
          end
        end
      end
      counter += 1
      print "Progress: #{counter} \r"
    end
  end

  desc "exec callbacks"
  task :callbacks => :environment do
    listings = Listing.where(:active => true).limit(1000)
    counter  = 0
    puts listings.count
    listings.each do |listing|
      begin
        listing.save(:validate => false)
      rescue => e
        puts e
      end
        counter += 1
        print "Progress: #{counter} \r"
    end
  end

  desc "Set kind"
  task :set_country_short => :environment do
    Listing.skip_callback(:save, :after, :update_account_listings)
    Listing.skip_callback(:save, :before, :get_account_data)

    listings = Listing.all
    counter  = 0
    listings.each do |listing|
      listing.account_country_short = listing.account.country_short
      listing.save(:validate => false)
      counter += 1
      print "Progress: #{counter} \r"
    end
    Listing.set_callback(:save, :before, :get_account_data)
    Listing.set_callback(:save, :after, :update_account_listings)
  end

  desc "Set kind"
  task :set_kind => :environment do
    countries = Country.all

    countries.each do |country|
      if country['prioritized'] == true
        puts "VIP"
        country.kind = 'vip'
        country.save(:validate => false)
        next
      end
      puts "OC"
      country.kind = 'oc'
      country.save(:validate => false)
    end
  end

  desc "Set default locale"
  task :set_default_locale => :environment do

    countries = Country.all

    countries.each do |country|
      if country.locales.empty?
        country.default_locale = 'en'
        msgid = "language.english"
        country.locales.push({msgid: msgid, locale: 'en'})
        country.save(:validate => false)
        next
      end
      locale = country.locales[0]['locale']
      country.default_locale = locale
      country.save(:validate => false)
    end
  end

  desc "Updates and resets the locale array to hold a hash"
  task :update_locale_fixer => :environment do
    countries = Country.where(:short.ne => 'SE')

    countries.each do |country|

      locale = country.locales[0]

      if not locale.blank? then
        #puts locale['locale']

        if locale['locale'].class == BSON::OrderedHash then
          puts locale['locale']['locale']
          new_locale = locale['locale']['locale']
          country.locales[0]['locale'] = new_locale
          country.save(:validate => false)
        end
      end
    end
  end

  desc "Updates and resets the locale array to hold a hash"
  task :update_locale_array => :environment do
    countries = Country.all

    countries.each do |country|

      country_msgid = country.msgid
      locale = country.locales[0]

      if not locale.blank? then
        puts 'hej'
        country.locales = []
        country.save
        msgid = "language" + country_msgid.gsub(/country/, '')

        country.locales = [{msgid: msgid, locale: locale}]
        country.save(:validate => false)
      end
    end
  end

  desc "Synchronize po files with db, creating keys and translations that do not exist"
  task :sync_gettext => :environment do
    folder = ENV['FOLDER']||'locale'
    gem 'grosser-pomo', '>=0.5.1'
    require 'pomo'
    require 'pathname'

    #find all intervac.po files we want to read
    pot_file = Pathname.new('locale/app.pot')

    puts "Starting syncing POT-files to DB..."
    Igettext.delete_all
    translations = Pomo::PoFile.parse(pot_file.read)
    #add all non-fuzzy translations to the database
    counter = 0
    translations.reject(&:fuzzy?).each do |t|
      next if t.msgid.blank? #atm do not insert metadata
      # Try to see if this already exists in the translations table
      exists = false
      current = Translations.where(:msgid => t.msgid).first
      if current
        exists = true
        if not t.comment.index(/^: model./).nil?
          puts "This is model so lets skip it: #{t.comment}"
          next
        end
      end
      counter += 1

      Igettext.find_or_create_by(msgid: t.msgid, location: t.comment, added: exists)
    end
    puts "Imported #{counter} translations."
  end

  desc "Read old translations into the translation engine database"
  task :read_old_translations => :environment do
    folder = ENV['FOLDER']||'locale'

    gem 'grosser-pomo', '>=0.5.1'
    require 'pomo'
    require 'pathname'

    #find all files we want to read
    po_files = []
    Pathname.new(folder).find do |p|
      next unless p.to_s =~ /\.po$/
      po_files << p
    end
    puts "Starting reading old translations to DB..."
    files = 0
    counter = 0
    #insert all their translation into the db
    num_files = po_files.length
    puts "Scanning #{num_files} files..."
    found_ids = []
    po_files.each do |p|
      #read translations from po-files
      locale = p.dirname.basename.to_s

      next unless locale =~ /^[a-z]{2}([-_][a-z]{2})?$/i
      next if p.basename.to_s == 'intervac.po'

      files += 1
      progress = " Progress: %.0f %% \r" % (files.to_f/num_files.to_f * 100)
      print progress
      namespace = p.basename.to_s.chomp('.po')
      translations = Pomo::PoFile.parse(p.read)
      #add all non-fuzzy translations to the database
      translations.reject(&:fuzzy?).each do |t|
        next if t.msgid.blank? #atm do not insert metadata

        msgid = t.msgid
        if namespace != 'intervac' then
          msgid = "#{namespace}.#{t.msgid}"
        end
        next if t.msgstr.blank?
        key = Igettext.where(:msgid => msgid).first
        next if key.nil?

        counter += 1
        found_ids.push(msgid)
        Translations.store_translation(locale, msgid, t.msgstr)
        if locale == 'en_GB' then
          # Adding default locale
          Translations.store_translation('en', msgid, t.msgstr)
        end
      end
    end
    found_ids.uniq!
    puts "Removing #{found_ids.length} msgids"
    Igettext.where(:msgid.in => found_ids).delete_all

    puts "\nImported #{files} old PO-files and #{counter} old translations."
  end

  desc "Sync default en locale to all other locales"
  task :sync_en_to_all_locales => :environment do
    en_texts = Translations.get_translations_for_locale('en')
    all_locales = Translations.available_locales
    c = 0
    en_texts.each do |t|
      c += 1
      all_locales.each do |l|
        next if l == 'en'
        Translations.store_translation(l, t[:msgid], nil, t[:category])
      end
    end
    puts c
  end

  desc "Read translations from i18n .yml files"
  task :read_translations_from_yml => :environment do
    folder = 'config/locales'
    gem 'grosser-pomo', '>=0.5.1'
    require 'pomo'
    require 'pathname'

    #find all files we want to read
    yml_files = ['config/locales/devise.en.yml', 'config/locales/devise_invitable.en.yml', 'config/locales/mongoid.en.yml', 'config/locales/mongoid.sv.yml']

    puts "Starting reading translations form yml to DB..."
    files = 0
    counter = 0
    #insert all their translation into the db
    num_files = yml_files.length
    puts "Scanning #{num_files} files..."
    locales = Translations.available_locales
    puts "----------------------"
    yml_files.each do |file|
      files += 1
      progress = " Progress: %.0f %% \r" % (files.to_f/num_files.to_f * 100)
      print progress
      locale = nil
      data = YAML::load(IO.readlines(file).join)
      data.each do |key,value|
        $levels_ary = []
        $return_ary = []

        locale = key
        if locale == 'en'
          locale = 'en_GB'
        end

        if locale == 'sv'
          locale = 'sv_SE'
        end

        # check that we only use lcoales that already exists

        if not locales.include?(locale)
          puts "Locale #{locale} do not exists"
          next
        end

        if value.kind_of? Hash
          recurs(value)
        end

        $return_ary.each do |trans|
          msgid = trans[0]
          msgstr = trans[1]

          next if msgstr.blank?
          #key = Igettext.where(:key => msgid).first
          #next if key.nil?
          counter += 1

          Translations.store_translation(locale, msgid, msgstr)
          if locale == 'en_GB' then
            # Adding default locale
            Translations.store_translation('en', msgid, msgstr)
          end
        end
      end
    end

    puts "\nImported #{files} old PO-files and #{counter} old translations."
  end

  desc "Dump all"
  task :dump_all => :environment do

    host = Mongoid.database.connection.host
    port = Mongoid.database.connection.port
    db_name =    Mongoid.database.name
    auths =      Mongoid.database.connection.auths
    collections = ['accounts', 'conversations', 'countries', 'environments', 'exchange_agreements', 'exchange_types', 'feedbacks', 'house_types', 'igettexts', 'languages', 'listing_statistics','listing_tags', 'listings', 'property_details', 'system.indexes', 'tags', 'translations', 'users']

    if auths.length > 0
      auth_string = "-u #{auths[0]["username"]} -p #{auths[0]["password"]}"
    end
    collections.each do |collection|
      cmd = "mongodump #{auth_string} --host #{host} --port #{port} -d #{db_name} -c #{collection} -o db/mongodumps/#{collection}"
      puts "Running '#{cmd}'"
      `#{cmd}`
    end
  end

  desc "Load all"
  task :load_all, [:src_db_name, :type] => :environment do |t, args|
    if not args.src_db_name
      puts " Missing argument db name"
      exit
    end

    host = Mongoid.database.connection.host
    port = Mongoid.database.connection.port

    src_db_name = args.src_db_name
    type = args.type ? args.type : "seed"

    target_db_name = Mongoid.database.name
    auths = Mongoid.database.connection.auths
    collections = ['accounts', 'conversations', 'countries', 'environments', 'exchange_agreements', 'exchange_types', 'feedbacks', 'house_types', 'igettexts', 'languages', 'listing_statistics','listing_tags', 'listings', 'property_details', 'system.indexes', 'tags', 'translations', 'users']

    if auths.length > 0
      auth_string = "-u #{auths[0]["username"]} -p #{auths[0]["password"]}"
    end

    collections.each do |collection|
      cmd = "mongorestore #{auth_string} --host #{host} --port #{port} --drop -d #{target_db_name} -c #{collection} db/mongodumps-#{type}/#{collection}/#{src_db_name}/#{collection}.bson"
      puts "Running '#{cmd}'"
      `#{cmd}`
    end
  end

  desc "Dump gettext"
  task :dump_gettext => :environment do

    host = Mongoid.database.connection.host
    port = Mongoid.database.connection.port
    db_name =    Mongoid.database.name
    auths =      Mongoid.database.connection.auths
    collections = ['igettexts']

    if auths.length > 0
      auth_string = "-u #{auths[0]["username"]} -p #{auths[0]["password"]}"
    end
    collections.each do |collection|
      cmd = "mongodump #{auth_string} --host #{host} --port #{port} -d #{db_name} -c #{collection} -o db/mongodumps/#{collection}"
      puts "Running '#{cmd}'"
      `#{cmd}`
    end
  end

  desc "Load gettext"
  task :load_gettext, [:src_db_name, :drop_collection] => :environment do |t, args|
    if not args.src_db_name
      puts " Missing argument db name"
      exit
    end
    drop = ' --drop'
    if args.drop_collection == 'keep'
      drop = ''
      puts "DROPING BEFORE ADDING"
    end

    host = Mongoid.database.connection.host
    port = Mongoid.database.connection.port
    src_db_name = args.src_db_name
    target_db_name = Mongoid.database.name
    auths =      Mongoid.database.connection.auths
    puts "Loading from #{args.src_db_name} into #{target_db_name}"

    collections = ['igettexts']

    if auths.length > 0
      auth_string = "-u #{auths[0]["username"]} -p #{auths[0]["password"]}"
    end
    collections.each do |collection|
      cmd = "mongorestore #{auth_string} --host #{host} --port #{port}#{drop} -d #{target_db_name} -c #{collection} db/mongodumps/#{collection}/#{src_db_name}/#{collection}.bson"
      puts "Running '#{cmd}'"
      `#{cmd}`
    end
  end

  desc "Dump translations"
  task :dump_translations => :environment do

    host = Mongoid.database.connection.host
    port = Mongoid.database.connection.port
    db_name =    Mongoid.database.name
    auths =      Mongoid.database.connection.auths
    collections = ['translations']

    if auths.length > 0
      auth_string = "-u #{auths[0]["username"]} -p #{auths[0]["password"]}"
    end
    collections.each do |collection|
      cmd = "mongodump #{auth_string} --host #{host} --port #{port} -d #{db_name} -c #{collection} -o db/mongodumps/#{collection}"
      puts "Running '#{cmd}'"
      `#{cmd}`
    end
  end

  desc "Load translations"
  task :load_translations, [:src_db_name, :drop_collection] => :environment do |t, args|
    if not args.src_db_name
      puts " Missing argument db name"
      exit
    end
    drop = ''
    if args.drop_collection == 'drop'
      drop = ' --drop'
      puts "DROPING BEFORE ADDING"
    end

    host = Mongoid.database.connection.host
    port = Mongoid.database.connection.port
    src_db_name = args.src_db_name
    target_db_name = Mongoid.database.name
    auths =      Mongoid.database.connection.auths
    puts "Loading from #{args.src_db_name} into #{target_db_name}"

    collections = ['translations']

    if auths.length > 0
      auth_string = "-u #{auths[0]["username"]} -p #{auths[0]["password"]}"
    end
    collections.each do |collection|
      cmd = "mongorestore #{auth_string} --host #{host} --port #{port}#{drop} -d #{target_db_name} -c #{collection} db/mongodumps/#{collection}/#{src_db_name}/#{collection}.bson"
      puts "Running '#{cmd}'"
      `#{cmd}`
    end
  end

  desc "Generate categories"
  task :generate_categories => :environment do
    puts "Generating categories based on msgid"
    translations = Translations.get_default_translations
    translations.each do |t|
      next unless t.category == 'other'
      category = /^(\w*)/i.match(t.msgid)[1]
      t.set_category(category)
    end
  end

  desc "Update translations from current po files. It tries to find the msgid in the translations and if it is found updates the data."
  task :update_translations_from_po => :environment do
    folder = ENV['FOLDER']||'locale'

    gem 'grosser-pomo', '>=0.5.1'
    require 'pomo'
    require 'pathname'

    #find all files we want to read
    po_files = []
    Pathname.new(folder).find do |p|
      next unless p.to_s =~ /\.po$/
      po_files << p
    end
    puts "Starting reading old translations to DB..."
    files = 0
    counter = 0
    #insert all their translation into the db
    num_files = po_files.length
    puts "Scanning #{num_files} files..."
    po_files.each do |p|
      #read translations from po-files
      locale = p.dirname.basename.to_s

      next unless locale =~ /^[a-z]{2}([-_][a-z]{2})?$/i
      next if p.basename.to_s == 'intervac.po'

      files += 1
      progress = " Progress: %.0f %% \r" % (files.to_f/num_files.to_f * 100)
      print progress
      namespace = p.basename.to_s.chomp('.po')
      begin
        translations = Pomo::PoFile.parse(p.read)
      rescue Exception => e
        puts "Dir: #{p.dirname.basename.to_s} File: #{p.basename.to_s}"
        puts e.message
        puts e.backtrace.inspect
        exit
      end
      #add all non-fuzzy translations to the database
      translations.reject(&:fuzzy?).each do |t|
        next if t.msgid.blank? #atm do not insert metadata

        msgid = t.msgid
        if namespace != 'intervac' then
          msgid = "#{namespace}.#{t.msgid}"
        end
        next if t.msgstr.blank?

        current_translation = Translations.where(:_id => "#{locale}.#{msgid}").first
        next if current_translation.nil?

        counter += 1
        current_translation.update_translation(t.msgstr)

      end
    end

    puts "\nUpdated #{counter} old translations."
  end
end

def recurs(dict)
  dict.each do |key, value|
    $levels_ary.push(key)
    if value.kind_of? Hash
      recurs(value)
    end
    if value.kind_of? String
      $return_ary.push( [$levels_ary.join('.'), value] )
    end
    $levels_ary.pop()
  end
end
