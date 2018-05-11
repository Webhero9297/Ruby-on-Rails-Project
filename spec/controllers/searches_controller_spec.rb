require 'rails_helper'

RSpec.describe SearchesController, type: :controller do
  before do
    request.env['REMOTE_ADDR'] = '127.0.0.0/8'
  end
  let (:expected_listings) { Listing.active_account.desc(:updated_at).limit(12) }

  describe 'GET #search' do

    context 'testing for open_for_exchange behavior' do
      it "does a search with the default params" do
        get :search
        expect(response).to be_ok

        # we will consider it as true for now the old business logic
        # was considering it as true with a giant workaronud.

        # It uses multiple params for the same value, which makes a
        # hash with multiple params that are unordered and may lead to
        # errors.
        expect(assigns(:open_for_exchange)).to eq nil

        expected = expected_listings.is_open_for_exchange.map(&:listing_number)
        expect(assigns[:listings].map(&:listing_number)).to match_array(expected)
      end

      it "sets the open for exchange param to false" do
        get :search, open_for_exchange: false
        expect(response).to be_ok
        expect(assigns(:open_for_exchange)).to eq false

        expected = expected_listings.map(&:listing_number)
        expect(assigns[:listings].map(&:listing_number)).to match_array(expected)
      end

      it "sets the open for exchange param to true" do
        get :search, open_for_exchange: true
        expect(response).to be_ok
        expect(assigns(:open_for_exchange)).to eq true
        expected = expected_listings.is_open_for_exchange.map(&:listing_number)
        expect(assigns[:listings].map(&:listing_number)).to match_array(expected)
      end
    end
    context 'testing for min_duration behavior' do
      it "testing the min_duration as <2> weeks" do
        get :search, min_duration: "2"
        expect(response).to be_ok
        expect(assigns(:min_duration)).to eq "2"
        expected = expected_listings.or({"exchange_dates.periodicity"=>"days","exchange_dates.length_of_stay" => {'$gte' => 2*7}},
                                        {"exchange_dates.periodicity"=>"weeks","exchange_dates.length_of_stay" => {'$gte' => 2}},
                                        {"exchange_dates.periodicity"=>"months","exchange_dates.length_of_stay" => {'$gte' => 2*0.25}}).map(&:listing_number)
        expect(assigns[:listings].map(&:listing_number)).to match_array(expected)
      end
    end
    context 'testing for experienced exchangers filter' do
      it "testing the experienced exchangers" do
        get :search, ee: true
        expect(response).to be_ok
        expect(assigns(:ee)).to eq true
        expected = expected_listings.where(:account_exchanges_made.gte => 1).map(&:listing_number)
        expect(assigns[:listings].map(&:listing_number)).to match_array(expected)
      end
    end
    context 'testing for pets filter behavior' do
      it "testing the pets filter as <with>" do
        get :search, pets: "with"
        expect(response).to be_ok
        expect(assigns(:pets)).to eq "with"
        expected = expected_listings.where(:account_pets.gte => 1).map(&:listing_number)
        expect(assigns[:listings].map(&:listing_number)).to match_array(expected)
      end

      it "testing the pets filter as <without>" do
        get :search, pets: "without"
        expect(response).to be_ok
        expect(assigns(:pets)).to eq "without"
        expected = expected_listings.where(:account_pets => 0).map(&:listing_number)
        expect(assigns[:listings].map(&:listing_number)).to match_array(expected)
      end

      it "testing the pets filter as default" do
        get :search
        expect(response).to be_ok
        expect(assigns(:pets)).to eq nil
        expected = expected_listings.map(&:listing_number)
        expect(assigns[:listings].map(&:listing_number)).to match_array(expected)
      end
    end

  end
end
