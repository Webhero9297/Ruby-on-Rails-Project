# encoding: UTF-8
namespace :convert do
  desc "Converts Match Alert to new format"
  task :match_alert => :environment do

    # No smoking, Dates, Capacity, Car exchange, Pet care wanted, Environment
    today = Date.today
    accounts = Account.where(:"searches.match_alert" => true)
    puts accounts.count
    allowed_filters= ['tag.non_smoking', 'tag.use_exchange_of_car', 'tag.pet_care_wanted',
                      'tag.pets_welcome', 'tag.children_welcome']
    accounts.each do |account|
      match_alert = account.match_alert
      match_alert.active = true
      location_names = []
      account.searches.each do |search|
        if match_alert.earliest_date
          if search.earliest_date and search.earliest_date > today and search.earliest_date < match_alert.earliest_date
            # Set earliest date if its in the future and less than the current date
            match_alert.earliest_date = search.earliest_date
          end
        else
          if search.earliest_date and search.earliest_date > today
            match_alert.earliest_date = search.earliest_date
          end
        end

        if search.latest_date and match_alert.latest_date and search.latest_date > match_alert.latest_date
          # Set latest date if its greater than the current date
          match_alert.latest_date = search.latest_date
        end

        if search.sleeping_capacity and search.sleeping_capacity > 0
          match_alert.capacity = search.sleeping_capacity
        end

        if not search.destination.blank?
          match_alert.reversed = true
        end

        if not search.environment.blank?
          match_alert.add_to_set(:environment_filters, search.environment)
        end

        if not search.filters.blank?
          match_alert.add_to_set(:house_filters, allowed_filters & search.filters)
        end


        location = {
            :name => search.q,
            :country_code => search.country_code,
            :lat => search.lat,
            :lng => search.lat,
            :ne_lat => search.ne_lat,
            :ne_lng => search.ne_lng,
            :sw_lat => search.sw_lat,
            :sw_lng => search.sw_lng
        }

        if not search.q.blank? and not location_names.include?(search.q)
          match_alert.save()
          match_alert.add_location(location)
          location_names.push(search.q)
        end


      end
      puts location_names.inspect
      puts match_alert.inspect
      puts "\n\n\n\n"
    end


  end
end
