# -*- coding: UTF-8 -*-
namespace :setup do
  desc "Adds an admin user to the system"
  task :add_admin_user => :environment do

    user = User.new(
      name: "Admin Intervac",
      email: "webmaster@intervac.com",
      account_admin: true,
      roles: ['admin'],
      password: "freshjava",
      password_confirmation: "freshjava",
    )
    user.save!(:validate => false)

    account = Account.new(
      country_short: "SE",
      account_owner: user.id,
      #account_number: 141337,
      activated_at: Time.utc(1956,12,24,12,00,00)
    )

    # Creates a stub for the contact details
    account.create_contact(
      name: "Admin Intervac",
      email: "webmaster@intervac.com"
    )

    account.create_profile()
    account.profile.create_presentation()
    account.profile.create_lifestyle()

    # Adds a dummy subscription for the Admin user.
    account.subscriptions.build(
      base_price: 0.00,
      renewal_price: 0.00,
      name: "Special price for you",
      duration: 100,
      periodicity: "years",
      kind: "paid",
      promotion_code: nil,
      currency: "EUR",
      renewal: false,
      active: true,
      expires_at: Time.utc(2100,12,24,12,00,00),
      order_id: nil
    )
    account.save!

    account.users.push(user)
    user.save!(:validate => false)
  end
end
