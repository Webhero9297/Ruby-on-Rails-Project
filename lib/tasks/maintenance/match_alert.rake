require_relative "../../../app/components/listing_search"

desc "Match alert that uses account.match_alert as a base"
task :match_alert_account, [:email] => :environment do |task, args|
  # Added for debugging purposes
  #
  # By using this email as a param, we can test the rake in our
  # production environment
  if args[:email]
    user = User.where(email: args[:email]).first
    puts "user not for #{args[:email]}" if user.blank?
    user_account = user.account
    puts "account not for #{args[:email]}" if user_account.blank?
    accounts = Account.where(_id: user_account._id)
  else
    accounts =
      Account.
        active_account.
        where(:match_alert.exists => true).
        where(:"match_alert.active" => true)
  end

  accounts.each do |account|
    begin
      new_listings = []

      listings = get_results(account)
      listings.each do |listing|
        next if account.sent_listings.include?(listing.id)

        new_listings.push(listing)
        account.add_to_set(:sent_listings, listing.id)
      end

      if new_listings.length > 0
        NotificationMailer.match_alert(account, new_listings).deliver
      end
    rescue => e
      NotificationMailer.oddity("Match alert errors: #{e}. On account #{account.account_number}").deliver
    end
  end
end

def get_results(account)
  current_user = User.find(account.account_owner)
  match_alert = account.match_alert

  params = {
    adults: match_alert.adults,
    capacity: match_alert.capacity,
    children: match_alert.children,
    earliest_date: match_alert.earliest_date,
    ee: match_alert.ee,
    environment_filters: match_alert.environment_filters,
    exchange_type_filters: match_alert.exchange_type_filters,
    hotlist: match_alert.hotlist,
    house_filters: match_alert.house_filters,
    house_type_filters: match_alert.house_type_filters,
    latest_date: match_alert.latest_date,
    locations: [],
    min_duration: match_alert.min_duration,
    pets: match_alert.pets,
    reversed: match_alert.reversed,
    reversed_area: match_alert.reversed_area,
    spoken_languages: match_alert.spoken_languages,
    surroundings: match_alert.surroundings
  }

  match_alert.locations.each do |location|
    params[:locations] << {
      ne_lat: location.ne_lat,
      ne_lng: location.ne_lng,
      sw_lat: location.sw_lat,
      sw_lng: location.sw_lng,
      country_short: location.country_code
    } unless location.ne_lat.blank?
  end

  listings = Listing.active_account.
             is_open_for_exchange.
             only_international(current_user).
             where(:_id.nin => account.sent_listings).
             limit(10)

  listing_search = ListingSearch.new(:match_alert, listings)
  listing_search.search(params)
end
