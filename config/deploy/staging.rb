require 'whenever/capistrano'

set :whenever_environment, defer { "staging" }

set :branch, "staging"
set :deploy_to, "/var/www/intervac"
set :deploy_env, 'staging'

role :app, "212.71.232.206"
role :web, "212.71.232.206"
