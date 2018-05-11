# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron
# Learn more: http://github.com/javan/whenever

set :chronic_options, :hours24 => true
set :output, "#{path}/log/cron.log"
env :PATH, '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games'

if @environment == 'production'
  every :day, :at => '03:30', :role => [:app] do
    rake "notifications:increment_exchanges_made"
  end

  every :day, :at => '04:00', :role => [:app] do
    rake "notifications:welcome_home"
  end

  every :day, :at => '04:15', :role => [:app] do
    rake "statistics:active_members_per_agent"
    rake "statistics:calculate_country_statistics"
  end

  every :day, :at => '04:30', :role => [:app] do
    rake "mongodb:export_agent_accounts"
  end

  every :day, :at => '04:45', :role => [:app] do
    rake "mongodb:export_all_accounts"
  end

  every :day, :at => '06:00', :role => [:app] do
    rake "automated:expirations"
  end

  every :day, :at => '06:30', :role => [:app] do
    rake "automated:green_light_reminder"
  end

  every :day, :at => '08:00', :role => [:app] do
    rake "automated:exchange_dates_reminder"
  end

  every :day, :at => '05:00', :role => [:app] do
    rake "match_alert_account"
  end

=begin
  every :day, :at => '09:00', :role => [:app] do
    rake "automated:reply_to_exchange_reminder"
  end
=end

  every :day, :at => '23:00', :role => [:app] do
    command "mongodump --quiet -o /tmp/mongodb && tar zcf /home/intervac/Dropbox/database/mongodb.tar.gz /tmp/mongodb && rm -rf /tmp/mongodb"
  end
end
