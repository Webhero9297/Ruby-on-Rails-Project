require 'rails_helper'

RSpec.describe ListingsHelper, type: :helper do
  describe "#show_listing_presentation_section" do
    it "returns false for an invalid presentation" do
      expect(show_listing_presentation_section(nil)).to be_falsy
    end

    it "returns true for a valid presentation" do
      expect(show_listing_presentation_section("valid")).to be_truthy
    end
  end
end
