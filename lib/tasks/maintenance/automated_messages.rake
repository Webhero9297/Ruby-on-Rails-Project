namespace :automated do
  desc "Match alert that uses searches as a base"
  task :expirations => :environment do
    counter = 0
    messages = AutomatedMessage.where(kind: 'trial_expiration')

    messages.each do |message|
      begin
        today = Date.today.to_s
        date_limit_low  = Time.parse("#{today} 00:00:00 UTC") + message.days.days
        date_limit_high = Time.parse("#{today} 23:59:59 UTC") + message.days.days

        accounts = Account.where(:country_short.in => message.countries)
        accounts = accounts.where(:subscriptions.matches => {:active => true, :kind => 'free', :expires_at.gte => date_limit_low, :expires_at.lte => date_limit_high})
        accounts.each do |account|
          NotificationMailer.trial_expiration(account.get_owner).deliver
          counter += 1
        end
      rescue => e
        NotificationMailer.oddity("Trial expiration errors: #{e}. On message #{message.id}").deliver
      end
    end

    messages = AutomatedMessage.where(:kind.in => ['first_expiration_notification', 'second_expiration_notification', 'third_expiration_notification'])
    counter = 0
    messages.each do |message|
      begin
        today = Date.today.to_s
        date_limit_low  = Time.parse("#{today} 00:00:00 UTC") + message.days.days
        date_limit_high = Time.parse("#{today} 23:59:59 UTC") + message.days.days

        if message.kind == 'third_expiration_notification'
          date_limit_low  = Time.parse("#{today} 00:00:00 UTC") - message.days.days
          date_limit_high = Time.parse("#{today} 23:59:59 UTC") - message.days.days
        end

        accounts = Account.where(:country_short.in => message.countries)
        accounts = accounts.where(:subscriptions.matches => {:active => true, :kind => 'paid', :expires_at.gte => date_limit_low, :expires_at.lte => date_limit_high})

        accounts.each do |account|
          counter += 1
          if message.kind == 'first_expiration_notification'
            NotificationMailer.first_expiration_notification(account.get_owner).deliver
            next
          end

          if message.kind == 'second_expiration_notification'
            NotificationMailer.second_expiration_notification(account.get_owner).deliver
            next
          end

          if message.kind == 'third_expiration_notification'
            NotificationMailer.third_expiration_notification(account.get_owner).deliver
          end

        end
      rescue => e
        NotificationMailer.oddity("Expiration errors: #{e}. On message #{message.id}").deliver
      end
    end
  end

  task :green_light_reminder => :environment do

    messages = AutomatedMessage.where(:kind.in => ['green_light_reminder'])
    messages.each do |message|
      today = Date.today.to_s
      (1..5).each do |i|
        date_limit_low = Time.parse("#{today} 00:00:00 UTC") - (message.days*i).days
        date_limit_high = Time.parse("#{today} 23:59:59 UTC") - (message.days*i).days

        listings = Listing.active_account.is_open_for_exchange.where(:account_country_short.in => message.countries)
        listings.each do |listing|
          begin
            account = listing.account
            if account and account.accessed_at and account.accessed_at >= date_limit_low and account.accessed_at <= date_limit_high
              NotificationMailer.green_light_reminder(account.get_owner).deliver
            end
          rescue => e
            NotificationMailer.oddity("Green light errors: #{e}. On message #{message.id}").deliver
          end
        end
      end
    end
  end

  task :exchange_dates_reminder => :environment do

    messages = AutomatedMessage.where(:kind.in => ['exchange_dates_reminder'])
    messages.each do |message|
      listings = Listing.active_account.is_open_for_exchange.with_outdated_exchange_dates
      listings.each do |listing|
        begin
          account = listing.account
          NotificationMailer.exchange_date_reminder(account.get_owner).deliver
        rescue e
          NotificationMailer.oddity("Exchange date reminder errors: #{e}. On message #{message.id}").deliver
        end
      end
    end
  end

  # Rules to send a reminder:
  #
  # * From messages that are member_to_member
  # * Get all users with a not replied exchange_request in the last 7 days
  # * The exchange_request should not be older than 2 months
  # * The user must not be expired
  # * Users should be warned just one time, even if there are many requests
  # * Users must receive a warning if the last one was more de 7 days ago
  desc "reminds the user to reply to an exchange reminder"
  task :reply_to_exchange_reminder, [:email] => :environment do |task, args|
    convs = Conversation.exchange_request_with_no_reply_since(7.days)

    # This whole `if` was added for debugging purposes
    # it's a good idea to keep it here so we can try in production
    if args[:email]
      user = User.where(email: args[:email]).first
      puts "user with email #{args[:email]} not found" && raise unless user
      account = user.account
      puts "account not found email #{args[:email]}" && raise unless account
      convs = convs.where(:participants.in => [account._id])
      puts "executing for #{convs.count} conversations"
    end

    convs.each do |conv|
      next unless conv.participants.count > 1

      # avoid expired or invalid accounts
      to_account = conv.get_conversation_partner(conv.started_by)
      next if to_account.blank? || to_account.is_expired?

      # avoid expired or invalid accounts
      begin
        from_account = Account.find(conv.started_by)
      rescue Mongoid::Errors::DocumentNotFound
        puts "warning: account #{conv.started_by} not found for conversation #{conv._id}. Skipping it..."
      end
      next if from_account.blank? || from_account.is_expired?

      last_reminder_sent = to_account.last_reminder_sent

      # We should only send messages for dates *older* than 7 days ago
      if last_reminder_sent.nil? || last_reminder_sent < 7.days.ago
        # `sent` variable is the message object if the message if the
        # email was sent correctly, otherwise is `false`
        sent = NotificationMailer.reply_to_exchange_reminder(
          to_account.get_owner, conv
        ).deliver

        if sent
          conv.request_reminders  = conv.request_reminders.to_i + 1
          conv.last_reminder_sent = Time.now
          conv.save

          to_account.update_attributes(last_reminder_sent: Time.now)
        end
      end
    end
  end

  task :expirations_special => :environment do
    messages = AutomatedMessage.where(:kind.in => ['third_expiration_notification'])
    counter = 0
    messages.each do |message|
      today = Date.today.to_s
      date_limit_low = Time.parse('2013-08-01 00:00:00 UTC')
      date_limit_high = Time.parse("#{today} 23:59:59 UTC")

      accounts = Account.where(:country_short.in => message.countries)
      accounts = accounts.where(:subscriptions.matches => {:active => true, :kind => 'paid', :expires_at.gte => date_limit_low, :expires_at.lte => date_limit_high})

      accounts.each do |account|
        counter += 1
          NotificationMailer.third_expiration_notification(account.get_owner).deliver
      end
    end

    messages = AutomatedMessage.where(:kind.in => ['second_expiration_notification'])
    counter = 0
    messages.each do |message|
      today = Date.today.to_s
      date_limit_low = Time.parse("#{today} 00:00:00 UTC")
      date_limit_high = Time.parse("#{today} 23:59:59 UTC") + 5.days

      accounts = Account.where(:country_short.in => message.countries)
      accounts = accounts.where(:subscriptions.matches => {:active => true, :kind => 'paid', :expires_at.gte => date_limit_low, :expires_at.lte => date_limit_high})

      accounts.each do |account|
        counter += 1
          NotificationMailer.second_expiration_notification(account.get_owner).deliver
      end
    end

    messages = AutomatedMessage.where(kind: 'trial_expiration')
    counter = 0
    messages.each do |message|
      today = Date.today.to_s
      date_limit_low = Time.parse('2013-08-01 00:00:00 UTC')
      date_limit_high = Time.parse("#{today} 23:59:59 UTC")

      accounts = Account.where(:country_short.in => message.countries)
      accounts = accounts.where(:subscriptions.matches => {:active => true, :kind => 'free', :expires_at.gte => date_limit_low, :expires_at.lte => date_limit_high})

      accounts.each do |account|
        NotificationMailer.trial_expiration(account.get_owner).deliver
        counter += 1
      end

    end
  end

  task :we_are_sorry => :environment do
    french = ['BL', 'FR', 'GP', 'MC', 'MF', 'MQ', 'NC', 'PF', 'PM', 'RE', 'TF', 'WF', 'YT', 'GF']
    c = 0
    sorries = Sorry.where(:sent => false, :country_code.nin => ['SE', 'NL']).limit(500)
    sorries.each do |sorry|
      account = Account.where(:_id => sorry.account_id).first
      if account
        c += 1

        if account.country_short == 'DE'
          NotificationMailer.sorry_de(account.get_owner).deliver
          sorry.set(:sent, true)
          next
        end

        if french.include?(account.country_short)
          NotificationMailer.sorry_fr(account.get_owner).deliver
          sorry.set(:sent, true)
          next
        end
        NotificationMailer.sorry(account.get_owner).deliver
      end
      sorry.set(:sent, true)
    end

    puts c
  end
end
