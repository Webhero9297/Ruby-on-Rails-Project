# -*- coding: UTF-8 -*-
namespace :setup do
  desc "Adds the system user to the system"
  task :add_system_user => :environment do
    # TODO Make sure there can be only one system user.
    user = User.new(
      name: "Intervac International",
      email: "system@intervac.com",
      account_admin: true,
      roles: 'system',
      password: "a6BYCQdbYn6e761",
      password_confirmation: "a6BYCQdbYn6e761",
    )
    user.save!
    
    account = Account.new(
      country_short: "W",
      account_owner: user.id,
    )
    
    # Creates a stub for the contact details
    account.create_contact(
      name: "Intervac International",
      email: "system@intervac.com"
    )
    
    account.create_profile()
    account.profile.create_presentation()
    account.profile.create_lifestyle()
    account.save
    
    account.users.push(user)
    
  end
end