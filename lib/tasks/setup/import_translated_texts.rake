# encoding: utf-8
namespace :setup do
  desc "Import translated countries into translation_texts"
  task :import_translated_countries  => :environment do
    
    puts "Loads the countries.xml file"
    doc = Nokogiri::XML(File.open("lib/tasks/data_files/countries.xml")) do |config|
      config.noblanks
    end
    
    puts "------------------------------------"
    puts "Starting the import of countries"
    
    found_ids = []
    doc.xpath('/RECORDS/RECORD').each do |place|
      long = place.at_xpath('countries.en_GB').text
      msgid = "country.#{long.downcase.gsub(/[\s\/]/,'_').gsub(/[\(\)\.]/,'')}"
      
      key = Igettext.where(msgid: msgid).first
      next if key.nil?
      found_ids.push(msgid)
      place.children.each do |child|
        if not ["countries.short", "countries.id", "agents.currency", "prices.amount", "countries.continent", "countries.priority_country"].include?(child.name)
          locale = child.name.to_s.gsub('countries.', '')
          value = child.content.to_s
          
          Translations.store_translation(locale, msgid, value, 'countries')
          if locale == 'en_GB' then
            # Adding default locale
            Translations.store_translation('en', msgid, value, 'countries')
          end
          
        end
      end
    end
    found_ids.uniq!
    puts "Removing #{found_ids.length} msgids"
    Igettext.where(:msgid.in => found_ids).delete_all
    
    puts "Import of countries finished"
    puts "------------------------------------"
    
  end
  
   
  desc "Import translated languages directly into translation_texts"
  task :import_translated_languages  => :environment do

   puts "Loads the languages.xml file"
   doc = Nokogiri::XML(File.open("lib/tasks/data_files/languages.xml")) do |config|
     config.noblanks
   end

   puts "------------------------------------"
   puts "Starting the import of languges"
   found_ids = []
   doc.xpath('/RECORDS/RECORD').each do |place|
     long = place.at_xpath('en_GB').text
     msgid = "language.#{long.downcase.gsub(/[\s\/]/,'_').gsub(/[\(\)\.]/,'')}"

     key = Igettext.where(msgid: msgid).first
     next if key.nil?
     found_ids.push(msgid)

     place.children.each do |child|
       if child.name != "short" and child.name != "id"
         locale = child.name.to_s
         value = child.content.to_s
         Translations.store_translation(locale, msgid, value, 'languages')
         if locale == 'en_GB' then
           # Adding default locale
           Translations.store_translation('en', msgid, value, 'languages')
         end
       end
     end
   end
   found_ids.uniq!
   puts "Removing #{found_ids.length} msgids"
   Igettext.where(:msgid.in => found_ids).delete_all
   
   puts "Import of languages finished"
   puts "------------------------------------"
   
  end
   
   
   
  desc "Import translated property details directly into translation_texts"
  task :import_translated_property_details  => :environment do

   puts "Loads the property_details.xml file"
   doc = Nokogiri::XML(File.open("lib/tasks/data_files/property_details.xml")) do |config|
     config.noblanks
   end

   puts "------------------------------------"
   puts "Starting the import of property details"
   found_ids = []
   doc.xpath('/RECORDS/RECORD').each do |place|
     long = place.at_xpath('en_GB').text
     msgid = "tag.#{long.downcase.gsub(/[\s\/]/,'_').gsub(/[\(\)\.]/,'').gsub(/[\(-)\.]/,'_')}"
     
     key = Igettext.where(msgid: msgid).first
     next if key.nil?
     found_ids.push(msgid)
     
     place.children.each do |child|
       if child.name != "short" and child.name != "id"
         locale = child.name.to_s
         value = child.content.to_s
         
         Translations.store_translation(locale, msgid, value, 'property details')
         if locale == 'en_GB' then
           # Adding default locale
           Translations.store_translation('en', msgid, value, 'property details')
         end
         
       end
     end
   end
   found_ids.uniq!
   puts "Removing #{found_ids.length} msgids"
   Igettext.where(:msgid.in => found_ids).delete_all
   
   puts "Import of property details finished"
   puts "------------------------------------"

  end

  desc "Import translated exchange types directly into translation_texts"
  task :import_translated_exchange_types  => :environment do

   puts "Loads the exchange_types.xml file"
   doc = Nokogiri::XML(File.open("lib/tasks/data_files/exchange_types.xml")) do |config|
     config.noblanks
   end

   puts "------------------------------------"
   puts "Starting the import of exchange types"
   found_ids = []
   doc.xpath('/RECORDS/RECORD').each do |place|
     long = place.at_xpath('en_GB').text
     msgid = "exchangetype.#{long.downcase.gsub(/[\s\/]/,'_').gsub(/[\(\)\.]/,'')}"

     key = Igettext.where(msgid: msgid).first
     next if key.nil?
     found_ids.push(msgid)

     place.children.each do |child|
       if child.name != "short" and child.name != "id"
         locale = child.name.to_s
         value = child.content.to_s

         Translations.store_translation(locale, msgid, value, 'exchange types')
         if locale == 'en_GB' then
           # Adding default locale
           Translations.store_translation('en', msgid, value, 'exchange types')
         end
       end
     end
   end
   found_ids.uniq!
   puts "Removing #{found_ids.length} msgids"
   Igettext.where(:msgid.in => found_ids).delete_all
   
   puts "Import of exchange types finished"
   puts "------------------------------------"

  end

end
