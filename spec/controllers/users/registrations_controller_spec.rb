require 'rails_helper'

RSpec.describe Users::RegistrationsController, type: :controller do
  let(:price_plan) { FactoryGirl.create(:price_plan) }
  before { request.env['REMOTE_ADDR'] = '127.0.0.0/8' }

  describe "GET #new" do
    before do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      expect(subject).to receive(:ssl_configured?).and_return(false)
    end

    it "should assign price_plan to an active one in case of wrong ids " do
      price_plan

      get :new, {account: {country_short: "BR"}, id: "50a41ef9e3bbfe1c62000212"}

      expect(response).to be_ok
      expect(assigns(:price_plan)).to be_an_instance_of PricePlan
      expect(assigns(:price_plan).active).to be_truthy
    end
  end
end
