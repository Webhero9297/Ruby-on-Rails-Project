app_dir = "/var/www/intervac/current"

working_directory app_dir

pid         File.join(app_dir, "tmp/pids/unicorn.pid")
stdout_path File.join(app_dir, "log/unicorn-stdout.log")
stderr_path File.join(app_dir, "log/unicorn-stderr.log")

listen 5055, :backlog => 1024

preload_app true

worker_processes Integer(ENV["WEB_CONCURRENCY"] || 5)
timeout 15
preload_app true

before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!
end

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end
