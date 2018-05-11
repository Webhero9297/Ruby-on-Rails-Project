require 'rails_helper'

RSpec.describe MatchAlert, :type => :model do
  let(:account) { FactoryGirl.create(:account) }

  context "#set_filters" do
    it "sets ee to false when params is empty" do
      expect(subject.ee).to be_falsey
      subject.set_filters({})
      expect(subject.ee).to be_falsey
    end

    it "sets ee to the correct param when it's set" do
      expect(subject.ee).to be_falsey
      subject.set_filters({"ee": true})
      expect(subject.ee).to be_truthy
    end
  end

  context "#clear_filters" do
    it "clear all filters" do
      expect(subject.ee).to be_falsey
      subject.set_filters({"ee": true})
      expect(subject.ee).to be_truthy

      subject.clear_filters
      expect(subject.ee).to be_falsey
    end
  end
end
