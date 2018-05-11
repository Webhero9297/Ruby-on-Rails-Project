# encoding: UTF-8
namespace :mongodb do
  desc "Adding js funciton to MongoDB"
  task :add_serverside_js => :environment do
    pad_js = %Q{
      function (n, len) {
        s = n.toString();
        if (s.length < len) {
            s = ('0000000000' + s).slice(-len);
        }
        return s;
      }
    }
    
    #if Account.collection.master['system.js'].find_one({'_id' => "pad"}).nil?
    Account.collection.master.db.add_stored_function("pad", pad_js)
    #end
  end
  
  
  desc "Adds the boolean terminated and account_terminated to accounts and listings"
  task :add_terminated_field => :environment do
    
    accounts = Account.unscoped.all
    
    accounts.each do |account|
      account.listings.each do |listing|
        listing.set(:account_terminated, false)
      end
      account.set(:terminated, false)
    end
    
  end

  desc "Rebuilds the accounts_listings collection"
  task :build_accounts_listings => :environment do
    cmd = "/usr/local/mongodb/bin/mongo localhost:27017/#{Mongoid::config.database.name} #{Rails.root}/lib/mapping.js"
    puts "Running '#{cmd}'"
    `#{cmd}`
    puts "Done"
  end

  task :export_agent_accounts => :environment do

    User.agent_profile.each do |agent|
      countries =  agent.agent_profile.get_assigned_countries_short_codes
      next if countries.empty?
      export_to_csv("#{agent.user_login}.csv", countries)
    end
  end

  task :export_all_accounts => :environment do
    export_to_csv("all_accounts.csv")
  end

end




def export_to_csv(filename, countries=nil)



  if countries.blank?
    account_id = []
    listings = Listing.all
    listings.each do |listing|
      account_id.append(listing.account_id)
    end
    account_id.uniq!
    accounts_with_no_listing = Account.where(:_id.nin => account_id)
  else
    account_id = []
    listings = Listing.where(:account_country_short.in => countries)
    listings.each do |listing|
      account_id.append(listing.account_id)
    end
    account_id.uniq!
    accounts_with_no_listing = Account.where(:_id.nin => account_id).where(:country_short.in => countries)
  end


  CSV.open("public/exports/#{filename}", "wb", {:col_sep => ';'}) do |csv|
    csv << %w(ListingNumber Name ContactAddress ContactPostalCode City State Country AccountNumber AccountCountry Status Expiration Activated Joined Exchanges Phone Mobile Mail Fax Website Adults Children ListingStreet ListingCity ListingPostal ListingCountry ListingCountryShort GoogleAddress)

    listings.each do |listing|
      account = listing.account
      csv << [
          listing.listing_number,
          account.contact.name.nil? ? 'NO VALUE' : account.contact.name,
          account.contact.address.nil? ? 'NO VALUE' : account.contact.address,
          account.contact.postal_code.nil? ? 'NO VALUE' : account.contact.postal_code,
          account.contact.postal_town.nil? ? 'NO VALUE' : account.contact.postal_town,
          account.contact.county.nil? ? 'NO VALUE' : account.contact.county,
          account.get_country.nil? ? 'NO VALUE' : I18n.t(account.get_country.msgid, :locale => 'en'),
          account.account_number.nil? ? 'NO VALUE' : account.account_number.to_i,
          account.country_short.nil? ? 'NO VALUE' : account.country_short,
          account.status,
          account.current_expires_at.nil? ? 'NO VALUE' : account.current_expires_at.strftime('%Y-%m-%d'),
          account.activated_at.nil? ? 'NO VALUE' : account.activated_at.strftime('%Y-%m-%d'),
          account.joined_at.nil? ? 'NO VALUE' : account.joined_at.strftime('%Y-%m-%d'),
          account.exchanges_made.nil? ? 'NO VALUE' : account.exchanges_made.to_i,
          account.contact.telephone.nil? ? 'NO VALUE' : account.contact.telephone,
          account.contact.mobile.nil? ? 'NO VALUE' : account.contact.mobile,
          account.contact.email.nil? ? 'NO VALUE' : account.contact.email,
          account.contact.fax.nil? ? 'NO VALUE' : account.contact.fax,
          account.contact.website.nil? ? 'NO VALUE' : account.contact.website,
          account.profile.number_of_adults.nil? ? 'NO VALUE' : account.profile.number_of_adults.to_i,
          account.profile.number_of_children.nil? ? 'NO VALUE' : account.profile.number_of_children.to_i,
          listing.street.nil? ? 'NO VALUE' : listing.street,
          listing.postal_town.nil? ? 'NO VALUE' : listing.postal_town,
          listing.postal_code.nil? ? 'NO VALUE' : listing.postal_code,
          listing.country.nil? ? 'NO VALUE' : I18n.t(listing.country, :locale => 'en'),
          listing.country_code.nil? ? 'NO VALUE' : listing.country_code,
          listing.google_formatted_address.nil? ? 'NO VALUE' : listing.google_formatted_address
      ]
    end

    accounts_with_no_listing.each do |account|
      csv << [
          'NO VALUE',
          account.contact.name.nil? ? 'NO VALUE' : account.contact.name,
          account.contact.address.nil? ? 'NO VALUE' : account.contact.address,
          account.contact.postal_code.nil? ? 'NO VALUE' : account.contact.postal_code,
          account.contact.postal_town.nil? ? 'NO VALUE' : account.contact.postal_town,
          account.contact.county.nil? ? 'NO VALUE' : account.contact.county,
          account.get_country.nil? ? 'NO VALUE' : I18n.t(account.get_country.msgid, :locale => 'en'),
          account.account_number.nil? ? 'NO VALUE' : account.account_number.to_i,
          account.country_short.nil? ? 'NO VALUE' : account.country_short,
          account.status,
          account.current_expires_at.nil? ? 'NO VALUE' : account.current_expires_at.strftime('%Y-%m-%d'),
          account.activated_at.nil? ? 'NO VALUE' : account.activated_at.strftime('%Y-%m-%d'),
          account.joined_at.nil? ? 'NO VALUE' : account.joined_at.strftime('%Y-%m-%d'),
          account.exchanges_made.nil? ? 'NO VALUE' : account.exchanges_made.to_i,
          account.contact.telephone.nil? ? 'NO VALUE' : account.contact.telephone,
          account.contact.mobile.nil? ? 'NO VALUE' : account.contact.mobile,
          account.contact.email.nil? ? 'NO VALUE' : account.contact.email,
          account.contact.fax.nil? ? 'NO VALUE' : account.contact.fax,
          account.contact.website.nil? ? 'NO VALUE' : account.contact.website,
          account.profile.number_of_adults.nil? ? 'NO VALUE' : account.profile.number_of_adults.to_i,
          account.profile.number_of_children.nil? ? 'NO VALUE' : account.profile.number_of_children.to_i,
          'NO VALUE',
          'NO VALUE',
          'NO VALUE',
          'NO VALUE',
          'NO VALUE',
          'NO VALUE'
      ]
    end

  end
end


