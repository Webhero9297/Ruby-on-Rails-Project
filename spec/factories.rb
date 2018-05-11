# coding: utf-8
require "securerandom"

FactoryGirl.define do
  factory :user do
    name "John Doe"
    account_admin true
    user_login "jonhdoe"
    email { Faker::Internet.email }
    password "P4s$w0rD"
    terms_and_conditions "1"
    account
  end

  factory :translations do
    value "England"
    msgid "country.england"
    category "Country"
    locale "en"
  end

  factory :subscription do
    expires_at Faker::Date.forward(800)
    active true
    account

    base_price 70.0
    renewal_price 60.0
    name "Full year membership"
    duration 1
    periodicity "years"
    kind "paid"
    promotion_code nil
    currency "EUR"
    renewal false
    upgrade false
  end

  factory :price_plan do
    base_price 130.0
    renewal_price 115.0
    name "Full year membership"
    duration 1
    periodicity "years"
    kind "paid"
    active true
    default true
    country
  end

  factory :listing do
    account
    account_exchanges_made Faker::Number.digit
    account_adults Faker::Number.digit
    account_children Faker::Number.digit
    account_country_short "EN"
    account_expires_at Faker::Date.forward(800)
    account_open_for_all_destinations Faker::Boolean.boolean
    account_pets Faker::Number.digit
    account_terminated Faker::Boolean.boolean
    account_wish_lists [{"location"=>[Faker::Address.latitude, Faker::Address.latitude], "ne_lat"=>Faker::Address.latitude, "ne_lng"=>Faker::Address.longitude, "sw_lat"=>Faker::Address.latitude, "sw_lng"=>Faker::Address.longitude, "country_code"=>Faker::Address.country_code, "destination"=>Faker::Address.country}]
    active Faker::Boolean.boolean
    added_to_hot_list nil
    bathrooms Faker::Number.digit
    bedrooms Faker::Number.digit
    bicycles Faker::Number.digit
    country Faker::Address.country
    country_code Faker::Address.country_code
    description Faker::Lorem.paragraph
    environment "environment.in_the_city"
    exchange_types ["exchangetype.exchange_of_home"]
    floor Faker::Number.digit.to_s
    google_formatted_address Faker::Address.street_address
    has_been_completed Faker::Boolean.boolean
    headline Faker::Lorem.sentence
    lat Faker::Address.latitude
    listing_number { SecureRandom.hex.upcase[0..7] }
    lng Faker::Address.longitude
    location [Faker::Address.latitude, Faker::Address.longitude]
    location_reversed [Faker::Address.longitude, Faker::Address.latitude]
    main_photo_caption Faker::Lorem.paragraph
    main_photo_path Faker::Placeholdit.image
    main_photo_placeholder Faker::Hipster.word
    map_visibility "guests"
    match_alert_expires Time.at(13243244355)
    open_for_exchange Faker::Boolean.boolean
    page_views Faker::Number.number(4)
    postal_code Faker::Address.postcode
    postal_town Faker::Address.postcode
    property_details { [['tag.children_welcome','tag.no_small_children'].sample,['tag.pets_welcome','tag.no_pets'].sample]}
    property_type Faker::Lorem.word
    searchable Faker::Boolean.boolean
    sleeping_capacity Faker::Number.digit
    street Faker::Address.street_name
    surrounding Faker::Hipster.word
    surroundings [{"name"=>Faker::Commerce.department[0..20], "distance"=>Faker::Number.decimal(2), "lat"=>Faker::Address.latitude, "lng"=>Faker::Address.longitude, "id"=>Faker::Hipster.word}]
    after(:create) do |listing|
      create_list(:exchange_date, 1, listing: listing)
    end
  end

  factory :account do
    account_number { Faker::Number.number(6) }
    terminated false
    country_short "BR"
    current_expires_at Faker::Date.forward(800)

    transient do
      subscription_count 1
      listing_count 1
    end

    after(:create) do |account, evaluator|
      create_list(:subscription, evaluator.subscription_count, account: account)
      create_list(:listing, evaluator.listing_count, account: account)
    end
  end

  factory :favorite do
    listing_id ""
    note ""
    account
  end

  factory :country do
    short "BR"
    continent "SA"
  end

  factory :conversation do
    started_by BSON::ObjectId(SecureRandom.hex[0..23])
    subject Faker::Hipster.word
    notification Faker::Boolean.boolean

    request_reminders Faker::Number.decimal(1)
    last_reminder_sent Faker::Date.forward(30)
  end

  factory :message do
    body Faker::Lorem.paragraph
    sent_by_user Faker::Hipster.word
    sent_by_account BSON::ObjectId(SecureRandom.hex[0..23])
    conversation
  end

  factory :message_status do
    message
    mailgun_id "<20200229055138.000.00000@messaging.intervac-homeexchange.com>"
    account_id BSON::ObjectId(SecureRandom.hex[0..23])
    delivered Faker::Boolean.boolean
    read Faker::Boolean.boolean
    failed Faker::Boolean.boolean
  end

  factory :exchange_date do
    listing
    note "test"
    earliest_date Date.today
    latest_date Date.today + 1
    length_of_stay Faker::Number.between(1, 12)
    periodicity ["years","months","days"].sample
  end
#  Could not get it to work yet =/
#  factory :match_alert do
#    active true
#  end

#  factory :location do
#    destination "Picpus, Paris, France"
#    country_code "FR"
#    ne_lat 48.850151
#    ne_lng 2.4611210000000483
#    sw_lat 48.81862899999999
#    sw_lng 2.383365099999992
#    match_alert
#  end
end
