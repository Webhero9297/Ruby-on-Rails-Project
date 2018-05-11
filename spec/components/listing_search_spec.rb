require 'rails_helper'

RSpec.describe ListingSearch do
  let(:listing) { Listing.where }

  search_params = {
    order_by: 'updated_at',
    ne_lat: '',
    ne_lng: '',
    sw_lat: '',
    sw_lng: '',
    country_short: '',
    environment_filters: '',
    house_filters: '',
    house_type_filters: '',
    exchange_type_filters: '',
    capacity: '',
    adults: '',
    children: '',
    pets: '',
    ee: '',
    spoken_languages: [],
    earliest_date: '',
    latest_date: '',
    min_duration: '',
    reversed: '',
    hotlist: '',
    surroundings: '',
    open_for_exchange: ''
  }

  it "does the filter for search" do
    ListingSearch.new.search(search_params)
  end

  context "#filter_by_geo" do
    it "for MapView" do
      ListingSearch.new.filter_by_geo(listing, :mapview, {})
    end

    it "for ListView" do
      ListingSearch.new.filter_by_geo(listing, :listview, {})
    end
  end

  it "#filter_by_environment" do
    ListingSearch.new.filter_by_environment(listing, "")
  end

  it "#filter_by_house_filters" do
    ListingSearch.new.filter_by_house_filters(listing, "")
  end

  it "#filter_by_exchange_types" do
    ListingSearch.new.filter_by_exchange_types(listing, "")
  end

  it "#filter_by_capacity" do
    ListingSearch.new.filter_by_capacity(listing, "")
  end

  it "#filter_by_adults" do
    ListingSearch.new.filter_by_adults(listing, "")
  end

  it "#filter_by_children" do
    ListingSearch.new.filter_by_children(listing, "")
  end

  it "#filter_by_pets" do
    ListingSearch.new.filter_by_pets(listing, "")
  end

  it "#filter_by_languages" do
    ListingSearch.new.filter_by_languages(listing, [])
  end

  it "#filter_by_date" do
    ListingSearch.new.filter_by_date(listing, "", "")
  end

  it "#filter_by_min_duration" do
    ListingSearch.new.filter_by_min_duration(listing, "")
  end

  it "#filter_by_reversed" do
    ListingSearch.new.filter_by_reversed(listing, "", [], "")
  end

  it "#filter_by_surroundings" do
    ListingSearch.new.filter_by_surroundings(listing, "")
  end

  it "#filter_by_ee" do
    ListingSearch.new.filter_by_ee(listing, "")
  end

  context "#filter_by_open_for_exchange" do
    it "returns the same listings for an empty string" do
      expect(
        ListingSearch.new.filter_by_open_for_exchange(listing, "")
      ).to eql(listing)
    end

    it "returns a different set of listings for a true value" do
      expect(
        ListingSearch.new.filter_by_open_for_exchange(listing, "true")
      ).to_not eql(listing)
    end
  end
end
