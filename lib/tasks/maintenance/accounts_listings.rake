namespace :account_listing do
  desc "Migrate data"
  task :migrate => :environment do
  	Listing.active_account.each do |l| l.set_new_account_data end
  end
end
