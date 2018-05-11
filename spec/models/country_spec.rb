require 'rails_helper'

RSpec.describe Country, :type => :model do
  let(:price_plan) { FactoryGirl.create(:price_plan) }

  context "#get_last_active_plan_for_country" do
    it "gets nil when there is no country" do
      expect(Country.get_last_active_plan("ZZ")).to be_nil
    end

    it "gets nil when there is no active plan" do
      FactoryGirl.create(:country, short: "ES")
      expect(Country.get_last_active_plan("ES")).to be_nil
    end

    it "gets a price plan when there is an active plan" do
      price_plan
      last_active = Country.get_last_active_plan("BR")
      expect(last_active).to_not be_nil
      expect(last_active).to eql(price_plan)
    end
  end
end
