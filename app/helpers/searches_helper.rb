module SearchesHelper
  # Interaction occour in case there is a current user (return is not nil) and
  # there is valid conversations.
  def had_interaction?(current_user, listing)
    c = Conversation.interactions(current_user, listing)
    c && c.any? ? true : false
  end

  def format_count(count)
    count > 1000 ? '1000+' : count
  end

  def get_country_code(user)
    user.account.country_short
  end

  def get_reversed_search_data(user)
    fields = ""
    user.account.listings.each_with_index do |listing, index|
      fields += hidden_field_tag("reversed_data[#{index}][lat]", listing.lat)
      fields += hidden_field_tag("reversed_data[#{index}][lng]", listing.lng)
      fields += hidden_field_tag("reversed_data[#{index}][country]", listing.country_code)
    end
    fields.html_safe
  end

  def get_country(user)
    if user.account.has_listing?
      return user.account.listings.first.country
    end
    user.account.get_country.msgid
  end

  def display_users_listing_locations(user, area)
    fields = user.account.listings.map do |listing|
      if area == "country"
        %Q("#{t(listing.country)}")
      elsif area == "continent"
        %Q("#{t("search_result.explanation.your_continent")}")
      else
        %Q("#{listing.postal_town}, #{t(listing.country)}")
      end
    end

    fields.uniq.join(' or ').html_safe
  end

  def display_wishlist_codes(wishlist)
    @have_wishlist = false

    html_row = '<tr class="wish-list-row"><td>%s</td><td>%s</td></tr>'
    codes = []
    wishlist.each do |row|
      if not row['country_code'].blank?
        codes.push(row['country_code'])
        @have_wishlist = true
      end
      break if codes.length > 5
    end

    if codes.length % 2 == 1
      codes.push('&nbsp;')
    end

    return_html = ""
    codes.each_slice(2) do |index|
      return_html += html_row % index
    end

    return_html.html_safe
  end

  def new_property_detail?(property)
    ['tag.free_internet_access', 'tag.computer_available', 'tag.hot_tub_jacuzzi', 'tag.air_conditioning', 'tag.central_heating', 'tag.fireplace', 'tag.baby_equipment', 'tag.toys_and_games', 'tag.washing_machine', 'tag.dishwasher', 'tag.clothes_dryer', 'tag.television', 'tag.piano', 'tag.guitar', 'tag.musical_instruments', 'tag.terrace_deck', 'tag.park_playground', 'tag.bbq', 'tag.sauna_private', 'tag.garage', 'tag.private_swimming_pool', 'tag.pet_care_wanted', 'tag.security_doorman'].include?(property)
  end

  def attributes_indoor(properties)
    indoor = ['tag.free_internet_access', 'tag.computer_available', 'tag.hot_tub_jacuzzi', 'tag.air_conditioning', 'tag.central_heating', 'tag.fireplace', 'tag.baby_equipment', 'tag.toys_and_games', 'tag.washing_machine', 'tag.dishwasher', 'tag.clothes_dryer', 'tag.television', 'tag.piano', 'tag.guitar', 'tag.musical_instruments']
    properties.where(:msgid.in => indoor).sort_by{ |p| indoor.index(p.msgid) }
  end

  def attributes_outdoor(properties)
    outdoor = ['tag.garden', 'tag.terrace_deck', 'tag.balcony', 'tag.park_playground', 'tag.bbq', 'tag.sauna_private', 'tag.garage', 'tag.private_swimming_pool']
    properties.where(:msgid.in => outdoor).sort_by{ |p| outdoor.index(p.msgid) }
  end

  def attributes_extras(properties)
    settings = [
      'tag.non_smoking', 'tag.lift_elevator', 'tag.suitable_for_disabled_people', 'tag.car_necessary',
      'tag.use_exchange_of_car', 'tag.seclusion_privacy', 'tag.use_of_boat', 'tag.pet_care_wanted',
      'tag.security_doorman', 'tag.pets_welcome', 'tag.children_welcome'
    ]
    properties.where(:msgid.in => settings).sort_by{ |p| settings.index(p.msgid) }
  end
end
