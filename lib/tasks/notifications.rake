# encoding: utf-8
namespace :notifications do
  desc "Sends out the welcome home emails with link to the feedback form."
  task :welcome_home => :environment do
    begin
      two_weeks_ago = (Date.today - 14.days).to_s
      date_limit_low = Time.parse("#{two_weeks_ago} 00:00:00 UTC")
      date_limit_high = Time.parse("#{two_weeks_ago} 23:59:59 UTC")
      # Original in production
      exchange_agreements = ExchangeAgreement.where(status: "agreed").where(:agreements.matches => {:end_date.gte => date_limit_low, :end_date.lte => date_limit_high})
      counter = 0
      exchange_agreements.each do |exchange_agreement|

        agreements = exchange_agreement.agreements.where(:end_date.gte => date_limit_low).where(:end_date.lte => date_limit_high).where(:welcome_sent => false)
        agreements.each do |agreement|
          owner_account = Account.find(agreement.owner)
          owner_user = owner_account.get_owner()
          partner_account_id = exchange_agreement.get_partner_account_id(agreement.owner)

          exchange_feedback = ExchangeFeedback.create_feedback(exchange_agreement.id, partner_account_id, owner_account.id, owner_user.id)
          owner_user.ensure_authentication_token!
          begin
            NotificationMailer.welcome_home(exchange_feedback, owner_user).deliver
          rescue => e
            NotificationMailer.oddity("Could not send out Welcome Home email to #{owner_user.email}. Error: #{e}").deliver
          end
          counter += 1
          agreement.set(:welcome_sent, true)
        end

      end
    rescue => e
      NotificationMailer.oddity("Could not send out welcome home email. Error: #{e}").deliver
    end
  end

  desc "Sends out the link to the feedback form."
  task :feedback_form => :environment do
    exchange_agreements = ExchangeAgreement.where(status: "agreed", :"agreements.end_date".lte => Time.now.utc - 14.days)
    exchange_agreements.each do |exchange_agreement|

      exchange_agreement.agreements.each do |agreement|
        if agreement.feedback_sent == false then
          feedback_account_id = ''
          account = Account.find(agreement.owner)
          account.users.each do |user|
            exchange_agreement.parties.each do |exchange_party|
              if exchange_party != user.account.id then
                feedback_account_id = exchange_party
              end
            end

            exchange_feedback = ExchangeFeedback.create_feedback(exchange_agreement.id, feedback_account_id, account.id, user.id)
            user.ensure_authentication_token!
            NotificationMailer.exchange_feedback(exchange_feedback, user).deliver
            puts "Sent feedback email to account: #{account.id} and user: #{user.id}"
          end

          agreement.set(:feedback_sent, true)
        end
      end
    end
  end

  desc "Sends out the welcome home emails with link to the feedback form for a single agreement."
  task :welcome_home_single => :environment do
    begin
      ea_id = "54b52dcbe3bbfe0b24000002"
      # Original in production
      exchange_agreement = ExchangeAgreement.find(ea_id)

      return if exchange_agreement.nil?

      counter = 0

      agreements = exchange_agreement.agreements.where(:welcome_sent => false)
      agreements.each do |agreement|
        owner_account = Account.find(agreement.owner)
        owner_user = owner_account.get_owner()
        partner_account_id = exchange_agreement.get_partner_account_id(agreement.owner)

        exchange_feedback = ExchangeFeedback.create_feedback(exchange_agreement.id, partner_account_id, owner_account.id, owner_user.id)
        #owner_user.ensure_authentication_token!

        NotificationMailer.welcome_home(exchange_feedback, owner_user).deliver
        counter += 1
        agreement.set(:welcome_sent, true)
      end
    rescue => e
      NotificationMailer.oddity("Could not send out welcome home email. Error: #{e}").deliver
    end
  end
end

namespace :deploy do
  task :send_notification => :environment do
    to = ["webmaster@intervac.com", "nancy@carroll.de", "the-board@intervac.org"]
    NotificationMailer.deploy_notification(to).deliver
  end
end
