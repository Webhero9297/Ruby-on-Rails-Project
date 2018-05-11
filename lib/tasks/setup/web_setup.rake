# encoding: utf-8
namespace :setup do
  
  desc "Imports the data from the old system from xml files into MongoDB collections."
  task :import_old_utility_data_into_mongodb => :environment do
    
    puts "-------------------------------------------------------------------------------------------------------------"
    puts "Starting importing countries, languages, property details, exchange types, house types and environments"
    puts "-------------------------------------------------------------------------------------------------------------"
    
    Rake::Task["setup:import_countries"].invoke
    Rake::Task["setup:import_languages"].invoke
    Rake::Task["setup:import_property_details"].invoke
    Rake::Task["setup:import_exchange_types"].invoke
    Rake::Task["setup:import_house_types"].invoke
    Rake::Task["setup:import_environments"].invoke
    
    puts "---------------------------------------------------"
    puts "Import of utility data finished"
    puts "---------------------------------------------------"
    
  end
  
  
  desc "Imports all the msgid from MongoDB collections in to the translation engine key table"
  task :import_msgid_for_utility_data_into_sql => :environment do
    
    puts "------------------------------------------------------------------------------"
    puts "Starting importing msgid for utility data into translation engine key table"
    puts "------------------------------------------------------------------------------"
    
    Rake::Task["setup:import_msgid_countries"].invoke
    Rake::Task["setup:import_msgid_languages"].invoke
    Rake::Task["setup:import_msgid_property_details"].invoke
    Rake::Task["setup:import_msgid_exchange_types"].invoke
    
    puts "---------------------------------------------------"
    puts "Import of msgid finished"
    puts "---------------------------------------------------"
    
  end
  
  
  desc "Imports old translations for the utility data into translation engine text table."
  task :import_translated_texts_into_sql => :environment do
    
    puts "------------------------------------------------------------------------------------------"
    puts "Starting importing old translations for utility data into translation engine text table"
    puts "------------------------------------------------------------------------------------------"
    
    Rake::Task["setup:import_translated_countries"].invoke
    Rake::Task["setup:import_translated_languages"].invoke
    Rake::Task["setup:import_translated_property_details"].invoke
    Rake::Task["setup:import_translated_exchange_types"].invoke
    
    puts "---------------------------------------------------"
    puts "Import of old translations finished"
    puts "---------------------------------------------------"
    
  end
  
  desc "Setup everything. And we mean everything!"
  task :import_everything => :environment do
    puts "------------------------------------------------------------------------------------------"
    puts "IMPORTING EVERYTHING"
    puts "------------------------------------------------------------------------------------------"
    Rake::Task["setup:add_admin_user"].invoke
    Rake::Task["setup:add_system_user"].invoke
    Rake::Task["setup:import_old_utility_data_into_mongodb"].invoke
    Rake::Task["setup:import_msgid_for_utility_data_into_sql"].invoke
    Rake::Task["setup:import_translated_texts_into_sql"].invoke
    puts "------------------------------------------------------------------------------------------"
    puts "IMPORTING OF EVERYTHING FINISHED"
    puts "------------------------------------------------------------------------------------------"
  end
  
  
  desc "Setup new staging"
  task :setup_staging => :environment do
    puts "------------------------------------------------------------------------------------------"
    puts "SETUP STAGING"
    puts "------------------------------------------------------------------------------------------"
    Rake::Task["maintenance:load_all"].invoke
    puts "------------------------------------------------------------------------------------------"
    puts "SETUP STAGING FINISHED"
    puts "------------------------------------------------------------------------------------------"
  end
  
  
  desc "Import users and agents"
  task :import_users_and_agents => :environment do
    puts "------------------------------------------------------------------------------------------"
    puts "IMPORTING USERS AND AGENTS"
    puts "------------------------------------------------------------------------------------------"
    Rake::Task["import:import_accounts_users_listings"].invoke
    Rake::Task["import:import_agents"].invoke
    Rake::Task["import:import_orders"].invoke
    Rake::Task["import:activate_users"].invoke
    Rake::Task["import:import_favorites"].invoke
    puts "------------------------------------------------------------------------------------------"
    puts "IMPORTING USERS AND AGENTS FINISHED"
    puts "------------------------------------------------------------------------------------------"
  end
  
  
  desc "Import countries, calling codes and coordinates"
  task :import_countries_codes_coords => :environment do
    puts "------------------------------------------------------------------------------------------"
    puts "IMPORTING COUNTRIES, CODES, AND COORDS"
    puts "------------------------------------------------------------------------------------------"
    Rake::Task["setup:import_countries"].invoke
    Rake::Task["setup:calling_codes"].invoke
    Rake::Task["setup:update_geo_for_countries"].invoke
    puts "------------------------------------------------------------------------------------------"
    puts "IMPORTING COUNTRIES, CODES, AND COORDS FINISHED"
    puts "------------------------------------------------------------------------------------------"
  end
  
  
  
end