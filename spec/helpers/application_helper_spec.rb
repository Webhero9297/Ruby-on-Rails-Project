require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  let(:account) { FactoryGirl.create(:account) }
  let(:user)    { FactoryGirl.create(:user) }
  let(:listing) { FactoryGirl.create(:listing) }

  describe "#can_contact" do
    it "returns true when the listing is not expired" do
      expect(listing.is_expired).to be_falsey
      expect(can_contact(user, listing)).to be_truthy
    end

    it "returns false when the listing is expired" do
      listing.account_expires_at = Date.parse("1 Apr 1950")
      expect(can_contact(user, listing)).to be_falsey
    end

    it "returns true for a valid account" do
      expect(helper.has_expired(account)).to be_falsey
      expect(can_contact(user, listing)).to be_truthy
    end
  end

  describe "#admin_session?" do
    it "returns true for an admin" do
      expect(session).to receive(:[]).and_return("admin")
      expect(admin_session?).to be_truthy
    end

    it "returns false when the user is not an admin" do
      expect(session).to receive(:[]).and_return("invalid")
      expect(admin_session?).to be_falsy
    end
  end

  describe "#get_current_dashboard" do
    it "returns 'member' when the dashboard is nil" do
      expect(session).to receive(:[]).and_return(nil)
      expect(get_current_dashboard).to eql("member")
    end

    it "returns the dashboard session if defined" do
      allow(session).to receive(:[]).and_return("dashboard")
      expect(get_current_dashboard).to eql("dashboard")
    end
  end
end
