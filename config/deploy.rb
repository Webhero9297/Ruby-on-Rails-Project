require 'capistrano/ext/multistage'
require 'bundler/capistrano'
require 'rollbar/capistrano'

set :stages, %w(production staging)
set :default_stage, "production"

set(:rollbar_env) { stage }
set :rollbar_token, '6d85fe91a14245ce96cab81fa461dad3'

default_run_options[:pty] = true
set :application, "intervac"
set :repository,  "git@github.com:intervac/intervac.git"

set :scm, :git
set :user, "intervac"
set :group, "www-data"

ssh_options[:port] = 4195
ssh_options[:forward_agent] = true

set :branch, "production"
set :use_sudo, false
set :keep_releases, 3

set :whenever_roles, ["app"]
set :whenever_command, "bundle exec whenever"

set :linked_dirs,  %w{bin log tmp/pids tmp/cache vendor/bundle}

before 'deploy:update_code', 'deploy:create_shared_dirs'

after 'deploy:update_code', 'deploy:symlink_database_yml'
after 'deploy:update_code', 'deploy:symlink_mongodb'
after 'deploy:update_code', 'deploy:symlink_exports'
after 'deploy:create_symlink', 'deploy:symlink_image_folders'

namespace :deploy do
  task :start do; end
  task :stop  do; end

  task :create_shared_dirs, :roles => :app do
    run "mkdir -p #{shared_path}/images"
    run "mkdir -p #{shared_path}/log"
    run "mkdir -p #{shared_path}/config"
    run "mkdir -p #{shared_path}/pids"
    run "mkdir -p #{shared_path}/cache"
    run "mkdir -p #{shared_path}/system"
    run "mkdir -p #{shared_path}/exports"
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  desc "Symlinks the database.yml"
  task :symlink_database_yml, :roles => :app do
    run "ln -nfs #{deploy_to}/shared/config/database.yml #{release_path}/config/database.yml"
  end

  desc "Symlinks the mongoid.yml"
  task :symlink_mongodb, :roles => :app do
    run "ln -nfs #{deploy_to}/shared/config/mongoid.yml #{release_path}/config/mongoid.yml"
  end

  desc "Symlinks the exports dir"
  task :symlink_exports, :roles => :app do
    run "ln -nfs #{deploy_to}/shared/exports #{release_path}/public/exports"
  end

  desc "Symlinks the image folders profiles, listings and agents"
  task :symlink_image_folders, :roles => :app do
    run "ln -nfs #{deploy_to}/images/listings #{release_path}/public/listings"
    run "ln -nfs #{deploy_to}/images/agents #{release_path}/public/agents"
    run "ln -nfs #{deploy_to}/images/profiles #{release_path}/public/profiles"
    run "ln -nfs #{deploy_to}/attachments #{release_path}/public/attachments"
  end

  namespace :web do
    task :disable, :roles => :web, :except => { :no_release => true } do
      require 'erb'
      on_rollback { run "rm #{shared_path}/system/maintenance.html" }

      reason   = ENV['REASON']
      deadline = ENV['UNTIL']

      template = File.read("./app/views/layouts/maintenance.html.erb")
      result = ERB.new(template).result(binding)

      put result, "#{shared_path}/system/maintenance.html", :mode => 0644
    end

    task :enable, :roles => :web, :except => { :no_release => true } do
      require 'erb'
      run "rm #{shared_path}/system/maintenance.html"
    end
  end

  task :send_notification, :roles => :web, :except => { :no_release => true } do
    run("cd #{deploy_to}/current && bundle exec rake deploy:send_notification RAILS_ENV=#{rails_env}")
  end
end
