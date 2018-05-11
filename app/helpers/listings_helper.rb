module ListingsHelper
  def show_listing_presentation_section(presentation)
    not presentation.blank?
  end

  def show_listing_contact_information(user, account)
    return unless user
    b = user_signed_in? && !has_expired(user.account) && !user.account.is_trial_subscription
    b = b && !account.listings.first.open_past_listing if account.listings.any?
    b = b && !user.account.listings.first.open_past_listing if user.account.listings.any?
    b
  end

  def show_listing_interaction_history(last_interaction, user, listing)
    return false unless user_signed_in?
    return false if user.account_id == listing.account_id
    return false if last_interaction.blank? or !user_signed_in?

    true
  end

  def addhttp(url)
    !url.match("^(http|https)://") ? "http://#{url}" : url
  end

  def show_listing_map(listing)
    if listing.map_visibility == 'hidden'
      return false
    end

    if listing.map_visibility == 'guests'
      return true
    end

    if user_signed_in? and listing.map_visibility == 'members'
      return true
    end

    false
  end

  def region_display(listing)
    if listing.state.blank?
      return I18n::t(listing.country)
    end

    "#{listing.state}, #{I18n::t(listing.country)}"
  end

  def listing_sub_headline(listing)
    if listing.state.blank?
      "#{listing.postal_town}, #{t(listing.country)} - #{listing.listing_number}"
    else
      "#{listing.postal_town}, #{t(listing.state)}, #{t(listing.country)} - #{listing.listing_number}"
    end
  end

  def ambassador_badge(listing, text = true)
    account = listing.account
    subscription = account.subscriptions.where(:active => true).first
    trial_days = (subscription.expires_at - DateTime.now.utc).to_i + 1
    if trial_days < 0
      trial_days = 0
    end

    badge_class, badge_text, badge_title = case account.exchanges_made.to_i
      when 0..2
        ['bronze', t('listing.badge.ambassador.bronze'), t('listing.badge.ambassador.bronze.title')]
      when 3..5
        ['silver', t('listing.badge.ambassador.silver'), t('listing.badge.ambassador.silver.title')]
      when 6..10
        ['gold', t('listing.badge.ambassador.gold'), t('listing.badge.ambassador.gold.title')]
      else
        ['platinum', t('listing.badge.ambassador.platinum'), t('listing.badge.ambassador.platinum.title')]
    end

    if text
      return content_tag(:div,content_tag(:img, '', src: image_path("badges/ambassador_#{badge_class}.png"), class: "member-badge") + content_tag(:span, badge_text, class: 'membership-badge-label'), class: 'membership-badge', title: badge_title)
    end

    content_tag(:img, '', src: image_path("badges/ambassador_#{badge_class}.png"),class: "member-badge",  title: badge_title)
  end


  def membership_badge(listing, text = true)
    account = listing.account
    return ambassador_badge(listing, text) if account.get_owner && account.get_owner.roles.include?("ambassador")

    subscription = account.subscriptions.where(:active => true).first
    trial_days = (subscription.expires_at - DateTime.now.utc).to_i + 1
    if trial_days < 0
      trial_days = 0
    end

    if listing.is_in_hot_list
      if text
        return content_tag(:div,content_tag(:img, '', src: image_path("badges/hot.png"), class: "member-badge") + content_tag(:span, t('listing.badge.hot'), class: 'membership-badge-label'), class: 'membership-badge', title: t('listing.badge.title.available_immediate_exchange'))
      end
      return content_tag(:div,content_tag(:img, '', src: image_path("badges/hot.png"), class: "member-badge"), class: 'membership-badge', title: t('listing.badge.title.available_immediate_exchange'))
    end

    badge_class, badge_text, badge_title = case account.exchanges_made.to_i
       when 0
         ['ready', t('listing.badge.ready'), t('listing.badge.text.no_exchanges_made')]
       when 1..2
         ['bronze', t('listing.badge.bronze'), t('listing.badge.bronze.title')]
       when 3..5
         ['silver', t('listing.badge.silver'), t('listing.badge.silver.title')]
       when 6..10
         ['gold', t('listing.badge.gold'), t('listing.badge.gold.title')]
       else
         ['platinum', t('listing.badge.platinum'), t('listing.badge.platinum.title')]
    end

    if text
      return content_tag(:div,content_tag(:img, '', src: image_path("badges/#{badge_class}.png"), class: "member-badge") + content_tag(:span, badge_text, class: 'membership-badge-label'), class: 'membership-badge', title: badge_title)
    end

    content_tag(:div,content_tag(:img, '', src: image_path("badges/#{badge_class}.png"), class: "member-badge"), class: 'membership-badge', title: badge_title)
  end

  def get_main_photo(listing, hsh = {})
    if listing.get_main_photo.nil?
      return image_tag('photos-coming-soon-458.jpg', alt: 'No photos')
    end

    image_class = hsh[:class]
    image, alt, width = case hsh[:size]
    when 60
      [listing.get_main_photo.image.size_60, listing.get_main_photo.caption, 60]
    when 170
      [listing.get_main_photo.image.size_170, listing.get_main_photo.caption, 170]
    when 230
      [listing.get_main_photo.image.size_230, listing.get_main_photo.caption, 230]
    when 458
      [listing.get_main_photo.image.size_458, listing.get_main_photo.caption, 458]
    else
      [listing.get_main_photo.image.size_458, listing.get_main_photo.caption, 458]
    end

    image_tag(image, width: width, alt: alt, class: image_class)
  end

  def exchange_badge(listing)
    account = listing.account
    subscription = account.subscriptions.where(:active => true).first
    trial_days = (subscription.expires_at - DateTime.now.utc).to_i + 1

    if listing.is_in_hot_list
      image = "hot"
      alt = "Hotlist"
      return image_tag("badges/#{image}.png", :alt => alt, :class => 'corner-tag')
    end

    if subscription.kind == 'free'
      if trial_days <= 0 or trial_days > 90
        image = "trial-0-day"
      else
        image = "trial-#{trial_days}-days"
      end
      alt = 'trial'
      return image_tag("badges/#{image}.png", :alt => alt, :class => 'corner-tag')
    end

    image, alt = case account.exchanges_made.to_i
    when 0
      ['ready', t('sitewide.rating.ready')]
    when 1..2
      ['bronze', t('sitewide.rating.bronze')]
    when 3..5
      ['silver', t('sitewide.rating.silver')]
    when 6..10
      ['gold', t('sitewide.rating.gold')]
    else
      ['platinum', t('sitewide.rating.platinum')]
    end

    image_tag("badges/#{image}.png", :alt => alt, :class => 'corner-tag')
  end

  # Puts out the correct link if a listing is added as a favorite or not.
  def act_as_favorite(listing, with_label = false, as_link = false)
    listing_id = listing.id
    favorites = []

    if not user_signed_in? or listing.account == current_user.account
      return
    end

    current_user.account.favorites.each do |favorite|
      favorites.push(favorite.listing_id)
    end
    # Remove links generated if the listing already is a favorite on the account
    if favorites.include?(listing_id.to_s)
      if with_label
        return link_to(content_tag('i','', class: 'icon-heart icon-white') + content_tag('span', t('global.unfavorite')), favorite_url(listing_id), remote: true, method: :delete, class: 'btn btn-warning bookmarked text', id: "favorite-#{listing_id}")
      end

      if as_link
        return link_to(content_tag('i','', class: 'icon-heart') + ' ' + t('favorites.remove_as_favorite'), favorite_url(listing_id), remote: true, method: :delete, class: 'btn btn-link bookmark link', id: "favorite-#{listing_id}")
      end

      return link_to(content_tag('i','', class: 'icon-heart icon-white'), favorite_url(listing_id), remote: true, method: :delete, class: 'btn btn-warning btn-small bookmarked', id: "favorite-#{listing_id}", title: t('favorites.delete'))
    end

    # Create links generated if the listing isn't a favorite on the account
    if with_label
      return link_to(content_tag('i','', class: 'icon-heart') + content_tag('span', t('global.favorite')), add_as_favorite_url(listing_id), remote: true, class: 'btn bookmark text', id: "favorite-#{listing_id}")
    end

    if as_link
      return link_to(content_tag('i','', class: 'icon-heart') + ' ' + t('listing.add_as_favorite'), add_as_favorite_url(listing_id), remote: true, class: 'btn btn-link bookmark link', id: "favorite-#{listing_id}")
    end

    return link_to(content_tag('i','', class: 'icon-heart'), add_as_favorite_url(listing_id), remote: true, class: 'btn btn-small bookmark', title: t('listing.add_as_favorite'), id: "favorite-#{listing_id}")
  end

  # Puts out the correct link if a listing is added as a favorite or not.
  def act_as_favorite_new(listing, favorites=nil,  with_label = false, as_link = false)
    listing_id = listing.id

    if not user_signed_in? or favorites.nil? or listing.account == current_user.account
      return
    end

    # Remove links generated if the listing already is a favorite on the account
    if favorites.include?(listing_id.to_s)
      if with_label
        return link_to(content_tag('i','', class: 'icon-heart icon-white') + content_tag('span', t('global.unfavorite')), favorite_url(listing_id), remote: true, method: :delete, class: 'btn btn-warning bookmarked text', id: "favorite-#{listing_id}")
      end

      if as_link
        return link_to(content_tag('i','', class: 'icon-heart') + ' ' + t('favorites.remove_as_favorite'), favorite_url(listing_id), remote: true, method: :delete, class: 'btn btn-link bookmark link', id: "favorite-#{listing_id}")
      end

      return link_to(content_tag('i','', class: 'icon-heart icon-white'), favorite_url(listing_id), remote: true, method: :delete, class: 'btn btn-warning btn-small bookmarked', id: "favorite-#{listing_id}", title: t('favorites.delete'))
    end

    # Create links generated if the listing isn't a favorite on the account
    if with_label
      return link_to(content_tag('i','', class: 'icon-heart') + content_tag('span', t('global.favorite')), add_as_favorite_url(listing_id), remote: true, class: 'btn bookmark text', id: "favorite-#{listing_id}")
    end

    if as_link
      return link_to(content_tag('i','', class: 'icon-heart') + ' ' + t('listing.add_as_favorite'), add_as_favorite_url(listing_id), remote: true, class: 'btn btn-link bookmark link', id: "favorite-#{listing_id}")
    end

    link_to(content_tag('i','', class: 'icon-heart'), add_as_favorite_url(listing_id), remote: true, class: 'btn btn-small bookmark', title: t('listing.add_as_favorite'), id: "favorite-#{listing_id}")
  end

  # Translates the true or false to Yes or No for property details
  def yes_or_no(listing, property_detail)
    if listing.property_details.include?(property_detail)
      return "Yes"
    end

    "No"
  end

  def yes_or_no_bool(bool)
    if bool
      return t('global.yes')
    end
    t('global.no')
  end

  def translate_periodicity(value)
    if value.downcase == 'year'
      return t('global.year')
    end

    if value.downcase == 'days'
      return t('global.days')
    end

    ''
  end

  def translate_paid_trial(value)
    if value.downcase == 'paid'
      return t('global.paid')
    end

    if value.downcase == 'trial'
      return t('global.trial')
    end

    ''
  end

  # Translates the true or false to Yes or No for property details into a green or red badge
  def yes_or_no_badge(listing, property_detail)
    if listing.property_details.include?(property_detail)
      return content_tag(:span, content_tag('i','', class: 'icon-ok-sign icon-white'), class: 'label label-success yes-no')
    end
    content_tag(:span, content_tag('i','', class: 'icon-ban-circle icon-white'), class: 'label label-important yes-no')
  end

  def has_valid_exchange_period(exchange_date)
    if exchange_date.latest_date > Time.now.utc then
      return true
    end

    false
  end

  def definition_list_item(label, value)
    if value.blank?
      return
    end

    "<dt>#{label}:</dt><dd>#{value}</dd>".html_safe
  end

  def default_list_item(label, value)
    if value.blank?
      return
    end

    "<li>#{label}: <strong>#{value}</strong></li>".html_safe
  end

  def order_property_details(properties, order)
    properties.any_in(msgid: order).sort_by {|p| order.index(p.msgid)}
  end

  # Rules for filtering different tagging options for listings, respect order
  def house_attributes
    ['tag.non_smoking', 'tag.lift_elevator', 'tag.suitable_for_disabled_people', 'tag.car_necessary', 'tag.use_exchange_of_car', 'tag.seclusion_privacy', 'tag.use_of_boat', 'tag.pet_care_wanted', 'tag.security_doorman']
  end

  def house_attributes_indoor
    ['tag.free_internet_access', 'tag.computer_available', 'tag.hot_tub_jacuzzi', 'tag.air_conditioning', 'tag.central_heating', 'tag.fireplace', 'tag.baby_equipment', 'tag.toys_and_games', 'tag.washing_machine', 'tag.dishwasher', 'tag.clothes_dryer', 'tag.television', 'tag.piano', 'tag.guitar', 'tag.musical_instruments']
  end

  def house_attributes_outdoor
    ['tag.garden', 'tag.terrace_deck', 'tag.balcony', 'tag.park_playground', 'tag.bbq', 'tag.sauna_private', 'tag.garage', 'tag.private_swimming_pool']
  end

  def house_extras
    ['tag.lift_elevator', 'tag.suitable_for_disabled_people', 'tag.car_necessary', 'tag.use_exchange_of_car', 'tag.seclusion_privacy', 'tag.use_of_boat', 'tag.non_smoking', 'tag.pet_care_wanted', 'tag.security_doorman']
  end

  def house_rules
    ['tag.non_smoking', 'tag.no_pets', 'tag.no_small_children', 'tag.pet_care_wanted']
  end

  def appliances
    ['tag.air_conditioning', 'tag.television', 'tag.video', 'tag.dvd', 'tag.computer_available', 'tag.free_internet_access']
  end

  def facilities
    ['tag.gdishwasher', 'tag.washing_machine', 'tag.shower', 'tag.clothes_dryer']
  end

  def children_appliances
    ['tag.baby_equipment', 'tag.park_playground']
  end

  def surrounding_activities
    ['tag.hiking']
  end

  ##
  # Used to filter a listings exchange reference listings
  def reference_link(reference, listing_number)
    if reference.listing_number_1 != listing_number
      return link_to(reference.listing_number_1, listing_path(reference.listing_number_1))
    end

    link_to(reference.listing_number_2, listing_path(reference.listing_number_2))
  end

  ##
  # Truncated alt text for images
  def truncate_alt_text(text, len=128)
    return '' if text.blank?

    text.truncate(len)
  end
end
