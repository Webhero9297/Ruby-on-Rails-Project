require 'rails_helper'

RSpec.describe Account, :type => :model do
  let(:account) { FactoryGirl.create(:account) }
  let(:user) { FactoryGirl.create(:user) }
  let!(:country) { FactoryGirl.create(:country) }
  let(:subscription) { FactoryGirl.create(:subscription) }
  let(:listing) { FactoryGirl.create(:listing) }

  it "gets the ownner for an account" do
    account.account_owner = user.id
    expect(account.get_owner).to eql(user)
  end

  context "#get_favorites" do
    it "gets an empty object when there is no favorites" do
      expect(account.get_favorites).to be_empty
    end
  end

  context "#current_subscription_expires_at" do
    it "returns nil when there is no subscription" do
      # just an quick workaround to return an empty relation
      # if you have a better solution please fix :)
      allow(account).to receive(:subscriptions).and_return(Account.where("1=2"))

      expect(account.current_subscription_expires_at).to be_nil
    end

    it "returns the time for the current subscription expire time" do
      account = subscription.account
      expect(account.current_subscription_expires_at).to be_an_instance_of(Time)
    end
  end
end
