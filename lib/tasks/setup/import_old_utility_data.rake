# encoding: utf-8
namespace :setup do
  desc "Imports all countries into MongoDB from cMySQL"
  task :import_countries => :environment do
    
    if ENV['RAILS_ENV'] == "production"
      puts "Using MySQL localhost"
      client = Mysql2::Client.new(:host => "127.0.0.1", :database => "ivac_ror_development", :username => "root", :password => "godjul05")
    else
      puts "Using MySQL socket"
      client = Mysql2::Client.new(:socket => "/usr/local/zend/mysql/tmp/mysql.sock", :database => "ivac_ror_development")
    end
    
    
    
    
    result = client.query("SELECT countries.id as country_id, countries.*, currency, prices.amount, priority_country FROM countries
                          LEFT OUTER JOIN agents ON countries.agent_id = agents.id
                          LEFT OUTER JOIN prices ON agents.id = prices.resource_id
                          WHERE continent IS NOT NULL
                          GROUP BY countries.short")
    
    
    Country.collection.drop
    puts "Collection dropped"
    puts "------------------------------------"
    puts "Starting the import of countries"
    
    counter = 0
    result.each do |row|
      counter += 1
      short = row['short']
      long = row['en_GB']
      continent = row['continent']
      prioritized = row['priority_country']
      currency = row['currency']
      base_price = row['amount']
      if base_price.nil?
        base_price = 70.00
      end
      
      
      kind = 'oc'
      if prioritized == '1'
        kind = 'vip'
      end
      
      msgid = "country.#{long.downcase.gsub(/[\s\/]/,'_').gsub(/[\(\)\.]/,'')}"
      
      locales = {
        'de' => 'de_DE',
        'da' => 'da_DK',
        'dk' => 'da_DK',
        'fi' => 'fi_FI',
        'fr' => 'fr_FR',
        'de' => 'de_DE',
        'en' => 'en',
        'uk' => 'en_GB',
        'gb' => 'en_GB',
        'us' => 'en_GB',
        'gr' => 'el_GR',
        'is' => 'is_IS',
        'it' => 'it_IT',
        'ja' => 'ja_JP',
        'jp' => 'ja_JP',
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
      
      locale = locales[short.downcase]
      if locale.nil?
         db_locales = [{msgid: "language.english", locale: "en"}]
         locale = "en"
      else
        new_short = locale.split('_')[0]
        language = Language.where(short: new_short.downcase).first
        if language.nil?
          puts "No language with short: #{new_short.downcase}"
          locale = "en"
          db_locales = [{msgid: "language.english", locale: "en"}]
        else
          language_msgid = language.msgid
          db_locales = [{msgid: language_msgid, locale: locale}, {msgid: "language.english", locale: "en"}]
        end
        
      end
      
      
      
      
      new_country = Hash.new
      new_country["msgid"] = msgid
      new_country["short"] = short
      new_country["continent"] = continent
      new_country["currency"] = currency
      new_country["prioritized"] = prioritized == '1' ? true : false
      new_country['kind'] = kind
      new_country['locales'] = db_locales
      new_country['default_locale'] = locale
      
      country = Country.create(new_country)
      
      trial_plan = country.price_plans.create!(name: '14 days trial membership', duration: 14, periodicity: 'days', base_price: 0.00, renewal_price: 0.00, kind: 'free', active: true)
      
      paid_plan = country.price_plans.create!(name: 'Full year membership', duration: 1, periodicity: 'years', base_price: base_price, renewal_price: (base_price.to_i * 0.85).ceil, kind: 'paid', active: true, default: true)
      
    end
    
    puts "Import of countries finished"
    puts "------------------------------------"
    puts "#{counter}: Countries imported"
  end
  
  
  desc "Updates geo coord for all countries"
  task :update_geo_for_countries => :environment do
    
    puts "Loads the coords.xml file"
    doc = Nokogiri::XML(File.open("lib/tasks/data_files/coords.xml")) do |config|
      config.noblanks
    end
    
    puts "------------------------------------"
    puts "Starting the import of coords"
    
    counter = 0
    doc.xpath('/wb:countries/wb:country').each do |place|
      
      isocode = place.at_xpath('wb:iso2Code').text
      c = Country.where(:short => isocode).first
      next if c.nil?
      lng = place.at_xpath('wb:longitude').text
      lat = place.at_xpath('wb:latitude').text
      puts "Lat: #{lat} -- lng: #{lng}"
      c.lng = lng.to_f
      c.lat = lat.to_f
      c.save
      
    end
    
  end
  
  
  desc "Imports calling code to the existing country collection"
  task :calling_codes => :environment do
    
    doc = Nokogiri::XML(File.open("lib/tasks/data_files/country_information.xml")) do |config|
      config.noblanks
    end
    
    doc.xpath('/countries/country').each do |country|
      current_country_short = country.at_xpath('iso2').text
      current_country = Country.where(short: current_country_short.to_s).first
      
      if not current_country.nil? then
        puts "Adding calling code #{country.at_xpath('callingcode').text} for #{country.at_xpath('name').text}"
        current_country.set(:calling_code, country.at_xpath('callingcode').text)
      end
      
    end
    
  end
  
  
  desc "Imports all languages into MongoDB from languages.xml"
   task :import_languages => :environment do

     puts "Loads the languages.xml file"
     doc = Nokogiri::XML(File.open("lib/tasks/data_files/languages.xml")) do |config|
       config.noblanks
     end

     puts "Collection dropped"
     Language.collection.drop

     puts "------------------------------------"
     puts "Starting the import of languges"

     counter = 0
     doc.xpath('/RECORDS/RECORD').each do |place|
       counter += 1
       short = place.at_xpath('short').text
       long = place.at_xpath('en_GB').text
       msgid = "language.#{long.downcase.gsub(/[\s\/]/,'_').gsub(/[\(\)\.]/,'')}"

       tag = Hash.new
       tag["msgid"] = msgid
       tag["short"] = short
       Language.create(tag)
     end

     puts "Import of languages finished"
     puts "------------------------------------"
     puts "#{counter}: Languages imported"

   end
  
  
   desc "Imports property details into MongoDB from property_details.xml"
   task :import_property_details => :environment do

     puts "Collection dropped"
     PropertyDetail.collection.drop

     $tags.each do |key, value|
        PropertyDetail.create(short: value['short'], msgid: value['msgid'], selectable: value['selectable'] )
      end
     
     puts "Import of property details finished"
     puts "------------------------------------"

   end
   
   desc "Imports alls exchange types into MongoDB from exchange_types.xml"
   task :import_exchange_types => :environment do
     
     puts "Collection dropped"
     ExchangeType.collection.drop
     
     exchange_types = [
       {"msgid" => "exchangetype.house_sitting", "short" => "house_sitting", "selectable" => false, "updated_at" => Time.now.utc, "created_at" => Time.now.utc },
       {"msgid" => "exchangetype.bed_&_breakfast", "short" => "bb", "selectable" => true, "updated_at" => Time.now.utc, "created_at" => Time.now.utc },
       {"msgid" => "exchangetype.double_exchange", "short" => "double_exchange", "selectable" => false, "updated_at" => Time.now.utc, "created_at" => Time.now.utc },
       {"msgid" => "exchangetype.hospitality_offered", "short" => "hospitality_offered", "selectable" => false, "updated_at" => Time.now.utc, "created_at" => Time.now.utc },
       {"msgid" => "exchangetype.want_to_house_sit", "short" => "want_to_house_sit", "selectable" => false, "updated_at" => Time.now.utc, "created_at" => Time.now.utc },
       {"msgid" => "exchangetype.hospitality_wanted", "short" => "hospitality_wanted", "selectable" => false, "updated_at" => Time.now.utc, "created_at" => Time.now.utc },
       {"msgid" => "exchangetype.long_term_exchange_wanted", "short" => "long_exchange", "selectable" => false, "updated_at" => Time.now.utc, "created_at" => Time.now.utc },
       {"msgid" => "exchangetype.non_simultaneous_exchange", "short" => "non_simultaneous", "selectable" => false, "updated_at" => Time.now.utc, "created_at" => Time.now.utc },
       {"msgid" => "exchangetype.hospitality_for_young_persons", "short" => "hospitality_for_young", "selectable" => false, "updated_at" => Time.now.utc, "created_at" => Time.now.utc },
       {"msgid" => "exchangetype.weekend_exchange", "short" => "weekend", "selectable" => false, "updated_at" => Time.now.utc, "created_at" => Time.now.utc },
       {"msgid" => "exchangetype.hospitality_by_young_persons", "short" => "hospitaility_by_young", "selectable" => false, "updated_at" => Time.now.utc, "created_at" => Time.now.utc },
       {"msgid" => "exchangetype.exchange_of_home", "short" => "exchange", "selectable" => true, "updated_at" => Time.now.utc, "created_at" => Time.now.utc },
       {"msgid" => "exchangetype.hospitality_exchange", "short" => "hospitality_exchange", "selectable" => false, "updated_at" => Time.now.utc, "created_at" => Time.now.utc },
       {"msgid" => "exchangetype.youth_exchange", "short" => "youth_exchange", "selectable" => false, "updated_at" => Time.now.utc, "created_at" => Time.now.utc },
       {"msgid" => "exchangetype.home_for_rent_only", "short" => "rent", "selectable" => true, "updated_at" => Time.now.utc, "created_at" => Time.now.utc }
     ]
     
     ExchangeType.collection.insert(exchange_types)
     puts "------------------------------------"
     puts "Inserted Exchange Types"
   end
   
   desc "Sets up house types from yml file"
   task :import_house_types => :environment do
     puts "------------------------------------"
     puts "Import house types from house_types.yml"
     HouseType.delete_all
     $house_types.each do |key, value|
       HouseType.create(short: value['short'], msgid: value['msgid'], selectable: value['selectable'] )
     end
     
   end

   desc "Sets up environments from yml file"
   task :import_environments => :environment do
     puts "------------------------------------"
     puts "Import environments from environments.yml"
     Environment.delete_all
     
     $environments.each do |key, value|
       Environment.create(short: value['short'], msgid: value['msgid'], selectable: value['selectable'] )
     end
     
   end
  
  
  
  
  
   desc "Setting priority on countries"
   task :set_kind_mysql => :environment do

     if ENV['RAILS_ENV'] == "staging"
       puts "Using MySQL localhost"
       client = Mysql2::Client.new(:host => "127.0.0.1", :database => "ivac_ror_development", :username => "root", :password => "godjul05")
     else
       puts "Using MySQL socket"
       client = Mysql2::Client.new(:socket => "/usr/local/zend/mysql/tmp/mysql.sock", :database => "ivac_ror_development")
     end

     result = client.query("SELECT short, priority_country FROM countries WHERE priority_country = 1")

     puts "Setting kind"

     result.each do |row|
       short = row['short']
       puts short
       kind = 'vip'
       country = Country.where(short: short).first
       next if country.nil?
       country.set(:kind, kind)
     end

     puts "Setting kind finished"
     puts "------------------------------------"
   end
  
  
  
  
  
  
end