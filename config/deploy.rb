require "rvm/capistrano"
require "bundler/capistrano"

set :rvm_ruby_string, :local              # use the same ruby as used locally for deployment
server "107.170.58.164", :web, :app, :db, primary: true

set :application, "yoloto"
set :scm, "git"
set :repository,  "git@github.com:dagosi89/yoloto.git"
set :branch, "master"

set :default_stage, "production"
set :user, "deployer"
set :deploy_to, "/home/#{user}/apps/#{application}"
set :deploy_via, :remote_cache
set :use_sudo, false

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

after "deploy", "deploy:cleanup" # keep only the last 5 releases
after "deploy:update_code", "deploy:migrate"

namespace :deploy do
  task :restart, roles: :app do
    run "touch #{current_path}/tmp/restart.txt"
  end

  task :symlink_config, roles: :app do
    run "ln -nfs /home/deployer/apps/yoloto/shared/config/database.yml #{release_path}/config/database.yml"
  end
  after "deploy:finalize_update", "deploy:symlink_config"
end

namespace :check do
  desc "Make sure local git is in sync with remote."
  task :revision, roles: :web do
    unless `git rev-parse HEAD` == `git rev-parse origin/#{branch}`
      puts "WARNING: HEAD is not the same as origin/#{branch}"
      puts "Run `git push` to sync changes."
      exit
    end
  end
  before "deploy", "check:revision"
  before "deploy:migrations", "check:revision"
  before "deploy:cold", "check:revision"
end