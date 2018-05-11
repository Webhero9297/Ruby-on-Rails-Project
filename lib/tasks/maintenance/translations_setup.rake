# encoding: utf-8
namespace :maintenance do
  
  desc "Harvest all text from views and mongodb. Syncing them to DB and import all old translations."
  task :harvest_and_sync_translations => :environment do
    
    puts "-------------------------------------------------------------------------------------------------------------"
    puts "Starting harvesting text, importing to db and reading all old translations."
    puts "-------------------------------------------------------------------------------------------------------------"
    
    #Rake::Task["gettext:find"].invoke # If we run this now it will clear out intervac.pot as we do not have any _() left
    Rake::Task["maintenance:sync_gettext"].invoke
    Rake::Task["maintenance:read_old_translations"].invoke
    Rake::Task["maintenance:read_translations_from_yml"].invoke
    Rake::Task["setup:import_translated_texts_into_sql"].invoke
    Rake::Task["maintenance:sync_en_to_all_locales"].invoke
    
    puts "---------------------------------------------------"
    puts "Import of translation data finished"
    puts "---------------------------------------------------"
    
  end
  
  task :harvest_and_sync_new_texts => :environment do
    #Rake::Task["gettext:find"].invoke # If we run this now it will clear out intervac.pot as we do not have any _() left
    Rake::Task["maintenance:sync_gettext"].invoke
  end

end