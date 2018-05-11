require 'rails_helper'

RSpec.describe Listing, :type => :model do
  let(:listing) { FactoryGirl.create(:listing) }

  it "returns an empty array when no image_set is received" do
    # TODO: check if filter_images is still used in the codebase
    expect(Listing.filter_images([], "whatever_category")).to be_empty
  end

  context "#city_and_country_headline" do
    it "returns the a headline with postal_town and country when there is no custom ones set up" do
      headline = [listing.postal_town, listing.country]
      expect(listing.city_and_country_headline).to eql(headline)
    end

    it "returns the custom city and country if they are defined" do
      custom_city = "London"
      custom_country = "England"

      listing.custom_nearest_city = custom_city
      listing.custom_country = custom_country

      headline = [custom_city, custom_country]
      expect(listing.city_and_country_headline).to eql(headline)
    end
  end
end
