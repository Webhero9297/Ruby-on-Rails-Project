source "https://rubygems.org"

gem "json", ">= 1.8.3"

gem "active_attr", "~> 0.8"
gem "activemerchant", "~> 1.43.1" # should de updated carefully
gem "best_in_place", "~> 3.1"
gem "bourbon", "~> 4.0.2"
gem "bson_ext", "~> 1.10"
gem "capistrano", "2.15.5" # it needs code changing
gem "capistrano-ext", "1.2.1" # it needs code changing
gem "carrierwave", "0.6.2" # needs Rails to be updated
gem "carrierwave-mongoid", "0.2.2", :require => "carrierwave/mongoid" # needs Rails to be updated
gem "declarative_authorization", "~> 0.5.7" # last commit 2013
gem "devise", "2.2.8" # needs Rails to be updated
gem "devise-encryptable", "0.1.2" # needs Rails to be updated
gem "devise_invitable", "1.1.8" # needs Rails to be updated
gem "formatize", "~> 1.1" # abandoned project
gem "geoip", "~> 1.6.0"
gem "gnista", "~> 1.0"
gem "hammerspace", "~> 0.1"
gem "jquery-rails", "~> 2.2.1" # this update must be in sync with jQuery update
gem "kaminari", "0.16.1" # needs Rails to be updated
gem "koala", "~> 2.4"
gem "mini_magick", "3.7.0" # needs to be updated with carrierwave
gem "modondo_mailgun", :path => "lib/modondo_mailgun"
gem "mongo", "1.10.2" # needs Rails to be updated
gem "mongo-i18n", "0.0.3" # needs Rails to be updated
gem "mongoid", "2.8.1" # needs Rails to be updated
gem "neat", "~> 1.8.0"
gem "newrelic_rpm", "~> 3.17.1"
gem "nokogiri", "~> 1.6.8"
gem "omniauth-facebook", "~> 4.0"
gem "rack-recaptcha", "~> 0.6.6", :require => "rack/recaptcha"
gem "rails", "~> 3.2.22"
gem "rails3-jquery-autocomplete", "~> 1.0.15"
gem "redcarpet", "~> 3.3"
gem 'remotipart', '~> 1.2' # able the file upload with JS
gem "rest-client", "1.6.7" # used just once for modondo_mailgun
gem "rollbar", "~> 2.13"
gem "select2-rails", "~> 4.0"
gem "sterile", "~> 1.0"
gem "strong_parameters", "~> 0.2.3"
gem "switch_user", "~> 0.9" # version 1+ breaks code. Must change it.
gem "test-unit", "~> 3.0"
gem "therubyracer", "~> 0.12.2"
gem "uuid", "~> 2.3.8"
gem "whenever", "~> 0.9", require: false
gem "yajl-ruby", "~> 1.3.0" # YAJL ruby used instead of JSON as it has a bug with i18n backend

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem "sass-rails", "3.2.6" # needs Rails to be upgraded
  gem "sass", "3.3"
  gem "uglifier", "2.0.1" # waiting for sass-rails to upgrade and test
  gem "yui-compressor", "~> 0.12.0"
end

gem "pry", :group => [:development, :test]

group :test do
  gem "database_cleaner", "~> 1.5"
  gem "factory_girl_rails", "~> 4.0"
  gem "faker", "~> 1.6"
  gem "rspec-rails", "~> 3.0"
end

group :development do
  gem "better_errors", "~> 2.1"
  gem "binding_of_caller", "~> 0.7"
  gem "letter_opener", "~> 1.4"
  gem "sqlite3", "~> 1.3"

  # necessary for more secure ssh keys
  # used by capistrano only
  gem "rbnacl"
  gem "rbnacl-libsodium"
  gem "bcrypt_pbkdf"
end
