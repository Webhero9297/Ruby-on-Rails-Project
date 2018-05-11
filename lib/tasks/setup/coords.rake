# encoding: utf-8
require 'nokogiri'
require 'open-uri'

namespace :setup do
  
  
  desc "Copies the location field data to specific lat lng fields."
  task :add_geo_from_location_on_listings => :environment do
    puts "Adding geo data"
    listings = Listing.all
    listings.each do |l|
      l.lat = l.location[1]
      l.lng = l.location[0]
      l.save
    end
    puts "Done!"
  end


  desc "Copies the location field data to specific lat lng fields."
  task :add_geo_to_location_on_countries => :environment do
    puts "Adding geo data"
    countries = Country.all
    countries.each do |c|
      c.set(:location, [c.lng, c.lat])
    end
    puts "Done!"
  end

end







