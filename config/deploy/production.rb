require 'whenever/capistrano'

set :whenever_environment, defer { "production" }

set :branch, "production"
set :deploy_to, "/var/www/intervac"
set :deploy_env, 'production'

role :app, "212.71.247.112"
role :web, "212.71.247.112"

namespace :deploy do
  desc "Symlinks search cgi coordinates file"
  task :symlink_search_cgi, :roles => :app do
    run "chmod ug+x #{release_path}/public/cgi/ivcoords.cgi"
    run "chmod ug+x #{release_path}/public/cgi/ivcoords_extended.cgi"
  end
end
