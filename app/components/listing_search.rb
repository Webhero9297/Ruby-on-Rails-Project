class ListingSearch
  def initialize(type=:listview, listings=nil)
    @type     = type
    @listings = listings
  end

  def search(params)
    listings = @listings || Listing.active_account_or_past_members
    listings = listings.order_by(
      [
        params[:order_by],
        params[:order_by] == 'updated_at' ? :desc : :asc
      ]
    ) if params[:order_by]

    locations = params[:locations] || []
    locations << {
      ne_lat: params[:ne_lat],
      ne_lng: params[:ne_lng],
      sw_lat: params[:sw_lat],
      sw_lng: params[:sw_lng],
      country_short: params[:country_short]
    } unless params[:ne_lat].blank?

    # Geo
    listings = filter_by_geo(listings, @type, locations)

    # Environment
    listings = filter_by_environment(listings, params[:environment_filters])

    # House filters
    listings = filter_by_house_filters(listings, params[:house_filters])

    # Exchange types
    listings = filter_by_exchange_types(listings, params[:exchange_type_filters])

    # Beds
    listings = filter_by_capacity(listings, params[:capacity])

    # Adults
    listings = filter_by_adults(listings, params[:adults])

    # Children
    listings = filter_by_children(listings, params[:children])

    # Pets
    listings = filter_by_pets(listings, params[:pets])

    # Exchanges made
    listings = filter_by_ee(listings, params[:ee])

    # Languages
    listings = filter_by_languages(listings, params[:spoken_languages])

    # Exchange dates
    listings = filter_by_date(
      listings,
      params[:earliest_date],
      params[:latest_date]
    )

    # Min duration
    listings = filter_by_min_duration(listings, params[:min_duration])

    # Reversed search (look for people interested in my area)
    listings = filter_by_reversed(listings, params[:reversed], params[:reversed_data], params[:reversed_area])

    # Hotlist
    listings = listings.in_hot_list if params[:hotlist]

    # Open of Exchange
    listings = filter_by_open_for_exchange(listings, params[:open_for_exchange])

    # Type of home
    unless params[:house_type_filters].blank?
      listings = listings.any_in(property_type: params[:house_type_filters])
    end

    # Surroundings
    listings = filter_by_surroundings(listings, params[:surroundings])

    listings
  end

  def filter_by_geo(listings, type, locations)
    # MapView must not filter by geolocation
    # it only uses the zoom feature
    return listings if type == :mapview

    geo_criterias = locations.map do |location|
      ne_lat, ne_lng, sw_lat, sw_lng = listings.add_bounds_padding(
        location[:ne_lat],
        location[:ne_lng],
        location[:sw_lat],
        location[:sw_lng]
      )

      {
        :lat.lte => ne_lat,
        :lat.gte => sw_lat,
        :lng.lte => ne_lng,
        :lng.gte => sw_lng
      }
    end

    unless geo_criterias.empty?
      listings = listings.any_of(*geo_criterias)
    end

    # Filtering also on country code
    country_codes = locations.map {|loc| loc[:country_short]}.uniq.compact
    unless country_codes.blank?
      listings = listings.where(:country_code.in => country_codes)
    end

    listings
  end

  def filter_by_environment(listings, env_filters)
    return listings if env_filters.blank?

    listings.any_in(environment: env_filters)
  end

  def filter_by_house_filters(listings, house_filters)
    return listings if house_filters.blank?

    listings.all_in(property_details: house_filters)
  end

  def filter_by_exchange_types(listings, exchange_type_filters)
    return listings if exchange_type_filters.blank?

    listings.any_in(exchange_types: exchange_type_filters)
  end

  def filter_by_capacity(listings, capacity)
    return listings unless capacity

    listings.where(:sleeping_capacity.gte => capacity)
  end

  def filter_by_adults(listings, adults)
    return listings unless adults

    listings.where(:account_adults.gte => adults)
  end

  def filter_by_children(listings, children)
    if children == 'with'
      listings.where(:account_children.gte => 1)
    elsif children == 'without'
      listings.where(:account_children     => 0)
    else
      listings
    end
  end

  def filter_by_pets(listings, pets)
    if pets == "with"
      listings.where(:account_pets.gte => 1)
    elsif pets == "without"
      listings.where(:account_pets     => 0)
    else
      listings
    end
  end

  def filter_by_languages(listings, languages)
    return listings if languages.blank?

    listings.where(:account_spoken_languages => {
       "$in" => languages
    })
  end

  def filter_by_date(listings, earliest_date, latest_date)
    unless latest_date.blank?
      begin
        unless latest_date.is_a? DateTime
          latest_date = DateTime.parse(latest_date)
        end

        listings = listings.where(
          :exchange_dates.matches => {
            :latest_date.gte   => latest_date.to_time.utc,
            :earliest_date.lte => latest_date.to_time.utc
          }
        )
      rescue ArgumentError
        # avoids errors with SQL Injection attacks with invalid dates
        # in this case, we will just ignore the date filter
      end
    end

    unless earliest_date.blank?
      begin
        unless earliest_date.is_a? DateTime
          earliest_date = DateTime.parse(earliest_date)
        end

        listings.where(
          :exchange_dates.matches => {
            :latest_date.gte   => earliest_date.to_time.utc,
            :earliest_date.lte => earliest_date.to_time.utc
          }
        )
      rescue ArgumentError
        # avoids errors with SQL Injection attacks with invalid dates
        # in this case, we will just ignore the date filter
      end
    end

    listings
  end

  def filter_by_min_duration(listings, min_duration)
    return listings if min_duration.blank?

    listings = listings.where(
      "$and" => [
        :"exchange_dates.latest_date".gte => Time.now,
        "$or" => [
          {:exchange_dates.matches => {:periodicity => "days", :length_of_stay   => {'$gte' => min_duration.to_i * 7   }}},
          {:exchange_dates.matches => {:periodicity => "weeks", :length_of_stay  => {'$gte' => min_duration.to_i       }}},
          {:exchange_dates.matches => {:periodicity => "months", :length_of_stay => {'$gte' => min_duration.to_i * 0.25}}}
        ]
      ]
    )

    listings
  end

  def filter_by_reversed(listings, reversed, reversed_data, reversed_area)
    return listings unless reversed

    # If user has listing, check to see if wish lists includes the listings location using both coords and country code
    if reversed_data
      criterias = []
      reversed_data.each do |data|
        # data is ["0", {"lat"=>"-23.0", "lng"=>"-46.0", "country"=>"BR"}]
        lat     = data[1]['lat'].to_f
        lng     = data[1]['lng'].to_f
        country = data[1]['country']

        case reversed_area
        when "city"
          criterias.push(Listing.get_by_wish_list(lat, lng).selector)
        when "country"
          criterias.push(Listing.get_by_wish_list_code(country).selector)
        when "continent"
          # Check to see if there any continent wishlists i.e Europe.
          criterias.push(Listing.get_by_wish_list(lat, lng).selector)
        end
      end

      criterias.each {|criteria| criteria.delete(:account_terminated) }
      listings.all_of criterias
    else
      listings.get_by_wish_list_code reversed
    end
  end

  def filter_by_surroundings(listings, surroundings)
    return listings if surroundings.blank?

    listings = listings.where(:surroundings.matches => {
      :id.in => surroundings
    })
  end

  def filter_by_open_for_exchange(listings, open_for_exchange)
    return listings unless open_for_exchange.try(:to_bool)

    listings.is_open_for_exchange
  end

  def filter_by_ee(listings, ee)
    return listings if ee.blank?

    listings.where(:account_exchanges_made.gte => 1)
  end
end
