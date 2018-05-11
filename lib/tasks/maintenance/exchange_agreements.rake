# encoding: utf-8
namespace :notifications do

  desc "Increments exchanges made"
  task :increment_exchanges_made => :environment do
    begin
      today = Date.today.to_s
      date_limit_low = Time.parse("#{today} 00:00:00 UTC")
      date_limit_high = Time.parse("#{today} 23:59:59 UTC")

      exchange_agreements = ExchangeAgreement.where(status: "agreed").where(:agreements.matches => {:end_date.gte => date_limit_low, :end_date.lte => date_limit_high})

      counter = 0
      exchange_agreements.each do |exchange_agreement|
        begin
          agreement = exchange_agreement.agreements.first
          partner_agreement = exchange_agreement.get_other_agreement(agreement)

          # We are building one of these for each exchange agreement.
          exchange_reference = {}

          exchange_reference[:listing_number_1] = agreement.listing_number
          exchange_reference[:account_id_1] = agreement.owner
          exchange_reference[:start_date] = agreement.start_date
          exchange_reference[:end_date] = agreement.end_date

          exchange_reference[:listing_number_2] = partner_agreement.listing_number
          exchange_reference[:account_id_2] = partner_agreement.owner

          exchange_reference[:exchange_agreement_id] = exchange_agreement.id


          ExchangeReference.add_references(exchange_reference)

          # Increment exchange made here after a successfull insert
          owner_account = Account.find(agreement.owner)
          owner_account.increment_exchanges_made
          partner_account = Account.find(partner_agreement.owner)
          partner_account.increment_exchanges_made

          counter += 1
        rescue
          #ExchangeReference already added
        end
      end
    rescue => e
      NotificationMailer.oddity("Could not increment exchanges made. Error: #{e}").deliver
    end
  end
end
