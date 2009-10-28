app_name = ask("\nWhat is your application called?")

run "rm public/index.html"
run "rm public/images/rails.png"
run "rm README"
run "cp config/database.yml config/database.yml.example"

file '.gitignore', <<-END
.DS_Store
log/*.log
tmp/**/*
tmp/restart.txt
config/database.yml
db/*.sqlite3
END

git :init
git :add => "."
git :commit => '-m "Initial commit."'

gem 'thoughtbot-shoulda', :source => "http://gems.github.com"
gem 'haml', :version => '>= 2.0.6' # for SASS
gem "json"
gem "javan-whenever", :lib => false, :source => "http://gems.github.com"
# gem "icalendar", :version => ">=1.1.0"
# gem 'mislav-will_paginate', :version => '~> 2.2.3', :lib => 'will_paginate',  :source => 'http://gems.github.com'

git :add => "."
git :commit => '-m "Added Base gems"'

plugin 'paperclip', :git => "git://github.com/thoughtbot/paperclip.git"
plugin 'restful_authentication', :git => "git://github.com/technoweenie/restful-authentication.git"
# plugin 'role_requirement', :git => 'git://github.com/timcharper/role_requirement.git'
# plugin 'aasm', :git => "git://github.com/rubyist/aasm.git"
plugin 'acts_as_list', :git => "git://github.com/rails/acts_as_list.git"
plugin 'acts_as_tree', :git => "git://github.com/rails/acts_as_tree.git"
plugin 'exception_notification', :git => "git://github.com/rails/exception_notification.git"
plugin 'ck_fu', :git => "git://github.com/r38y/ck_fu.git"
# plugin 'mobile-fu', :git => "git://github.com/brendanlim/mobile-fu.git"
# plugin 'spawn', :git => "git://github.com/tra/spawn.git"
# plugin 'comatose', :git => "git://github.com/darthapo/comatose.git"
# plugin '', :git => ""
# plugin 'invoicing', :git => 'git://github.com/ept/invoicing.git'
# gem 'ruby-openid'
# plugin 'open_id_authentication', :git => 'git://github.com/rails/open_id_authentication.git'

## Plugins for BDD
# plugin 'jrails', :git => 'git://github.com/aaronchi/jrails.git '
# plugin 'uberkit', :git => 'git://github.com/mbleigh/uberkit.git'
# plugin 'rspec', :git => "git://github.com/dchelimsky/rspec.git"
# plugin 'rspec-rails', :git => "git://github.com/dchelimsky/rspec-rails.git"
# plugin 'factory_girl', :git => "git://github.com/thoughtbot/factory_girl.git"
# plugin 'cucumber', :git => "git://github.com/aslakhellesoy/cucumber.git"
# generate("rspec")

git :add => "."
git :commit => '-m "Added plugins"'


if yes?("\nRun rake gems:install? (yes/no)")
  rake("gems:install", :sudo => true)
end

# generate('controller', 'static')
# generate('twitter_auth')
# generate('comatose_migration')
# generate('paperclip')

# generate("authenticated", "user sessions --include-activation --stateful --aasm --rspec --old-passwords")
# generate('roles','Admin User')
# generate('roles','Executive User')

git :add => "."
git :commit => '-m "Generated stuff"'

file 'public/stylesheets/sass/master.sass', <<-SASS
body
  :font-family Arial, sans-serif
  :background #cef
  :margin 0
  :padding 0
  :color #333

a
  :color #06b
  :font-weight bold
  img
    :border 0

.clearfix
  :clear both

#wrapper
  :background white
  :padding 1.5em 2em
  :width 55em
  :-moz-border-radius 1em
  :-webkit-border-radius 1em
  :border-radius 1em
  :margin 1em auto 0.5em

#footer
  :text-align center
  :font-size 0.8em
  :color #666
  :padding-bottom 1.5em

#header
  h1
    :float left
    :font-size 3em
    :margin 0
    :padding 0
    a
      :color #057
      :text-decoration none
    :margin-bottom 0.3em
  #user_bar
    :float right
    :margin-top 1.2em
    img
      :vertical-align middle

p
  :line-height 150%

div.flash
  :padding 4px 8px
  :-moz-border-radius 4px
  :-webkit-border-radius 4px
  :border-radius 4px
  :border 2px solid #ccc
  :margin 10px 0

div.error
  :background #fcc
  :border-color #911
  :color #311

div.notice
  :background #cfc
  :border-color #191
  :color #131
SASS

file 'app/controllers/application_controller.rb', <<-RUBY
class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  include AuthenticatedSystem
  include ExceptionNotifiable
  before_filter :set_redirect_back

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  def set_redirect_back
    session[:back] = params[:back] if params[:back]
  end
  
  def redirect_back_or(path)
    if session[:back]
      redirect_to session[:back]
      session[:back] = nil
      return
    end
    if params[:back]
      redirect_to params[:back]
      return
    end
    redirect_to :back if :back
    rescue ActionController::RedirectBackError
      redirect_to path
  end
end
RUBY

file 'config/deploy.rb', <<-RUBY
set :stages, %w(staging production)
set :default_stage, "staging"
require 'capistrano/ext/multistage'

set :application, "#{app_name}"
set :scm, :git
default_run_options[:pty] = true
set :repository, "git@github.com:LeipeLeon/#{app_name}.git"

set :repository_cache, "git_master"
set :deploy_via, :remote_cache
set :branch, "master"
set :scm_verbose, :true

set :use_sudo, false

set :chmod777, %w(public log)

namespace :deploy do
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch \#\{current_path}/tmp/restart.txt"
  end

  [:start, :stop].each do |t|
    desc "\#\{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end
  
  [:import, :export].each do |t|
    desc "\#\{t} content for comatose, do a deploy first"
    task ('coma_'+t.to_s).to_sym, :roles => :app do 
      rake = fetch(:rake, "rake")
      rails_env = fetch(:rails_env, "production")

      run "cd \#\{current_release}; \#\{rake} RAILS_ENV=\#\{rails_env} comatose:data:\#\{t}"
    end
  end

  desc "Set the proper permissions for directories and files"
  task :before_restart do
    run(chmod777.collect do |item|
      "chmod 777 -R \#\{current_path}/\#\{item}"
    end.join(" && "))
  end

  desc "Create shared/config" 
  task :after_setup do
    # copy dev version of database.yml to alter later
    run "if [ ! -d \"\#\{deploy_to}/\#\{shared_dir}/config\" ] ; then mkdir \#\{deploy_to}/\#\{shared_dir}/config ; fi"
  end

  after "deploy:finalize_update", "deploy:symlink_config"
  desc "Link to database.yml in shared/config" 
  task :symlink_config do
    ['database'].each {|yml_file|
      # remove  the git version of yml_file.yml
      run "if [ -e \"\#\{release_path}/config/\#\{yml_file}.yml\" ] ; then rm \#\{release_path}/config/\#\{yml_file}.yml; fi"
    
      # als shared conf bestand nog niet bestaat
      run "if [ ! -e \"\#\{deploy_to}/\#\{shared_dir}/config/\#\{yml_file}.yml\" ] ; then cp \#\{deploy_to}/\#\{shared_dir}/\#\{repository_cache}/config/\#\{yml_file}.example.yml \#\{deploy_to}/\#\{shared_dir}/config/\#\{yml_file}.yml; fi"
    
      # link to the shared yml_file.yml
      run "ln -nfs \#\{deploy_to}/\#\{shared_dir}/config/\#\{yml_file}.yml \#\{release_path}/config/\#\{yml_file}.yml" 
    }
    # set deployment date
    run "date > \#\{current_release}/DATE"
  end

  after "deploy:symlink", "deploy:update_crontab"
  desc "Update the crontab file"
  task :update_crontab, :roles => :db do
    # run "cd \#\{release_path} && whenever --update-crontab \#\{application}"
  end

end
RUBY


file 'config/deploy/production.rb', <<-RUBY
role :app, "webs"
role :web, "webs"
role :db,  "webs", :primary => true
set :user, 'sneaker'
set :rails_env, 'production'
set :deploy_to, "/home/sneaker/apps/\#\{application}"
RUBY

file 'config/deploy/staging.rb', <<-RUBY
role :app, "webs"
role :web, "webs"
role :db,  "webs", :primary => true
set :user, 'sneaker'
set :rails_env, 'staging'
set :deploy_to, "/var/www/apps/\#\{application}_staging"
RUBY

file 'app/controllers/static_controller.rb', <<-RUBY
class StaticController < ApplicationController
  def index
    @users = User.all(:order => "created_at DESC", :limit => 16)
  end
end
RUBY

file 'config/exception.yml', <<-YAML
development:
    recipients: leonb@beriedata.nl
    sender: '"Leon Berenschot" <leonb@beriedata.nl>'
    prefix: "[#{app_name} Devel] "
test:
    recipients: leonb@beriedata.nl
    sender: '"Leon Berenschot" <leonb@beriedata.nl>'
    prefix: "[#{app_name} Test] "
staging:
    recipients: leonb@beriedata.nl
    sender: '"Leon Berenschot" <leonb@beriedata.nl>'
    prefix: "[#{app_name} Staging] "
production:
    recipients: leonb@beriedata.nl
    sender: '"Leon Berenschot" <leonb@beriedata.nl>'
    prefix: "[#{app_name}] "
YAML

file 'config/google.yml', <<-YAML
production:
    analytics: ""
staging: 
    analytics: ""
development: 
    analytics: ""
YAML

file 'config/email_settings.yml', <<-YAML
development:
  host: http://#{app_name}.local
  sender: Development <leonb@beriedata.nl>
  subject: "[#{app_name} Devel] "

test:
  host: http://#{app_name}.local
  sender: Test <leonb@beriedata.nl>
  subject: "[#{app_name} Test] "

staging:
  host: http://office.beriedata.nl/#{app_name}
  sender: Staging <leonb@beriedata.nl>
  subject: "[#{app_name} Staging] "

production:
  host: http://#{app_name}.com
  sender: Avartize <info@#{app_name}.com>
  subject: "[#{app_name}] "
YAML

# run "cp config/twitter_auth.yml config/twitter_auth.yml.example"

initializer 'email_settings.rb', <<-CODE
env = ENV['RAILS_ENV'] || RAILS_ENV
EMAIL = YAML.load_file(RAILS_ROOT + '/config/email_settings.yml')[env]
CODE

initializer 'exception_notifier.rb', <<-CODE
env = ENV['RAILS_ENV'] || RAILS_ENV
EXCEPTION_NOTIFIER = YAML.load_file(RAILS_ROOT + '/config/exception.yml')[env]
ExceptionNotifier.exception_recipients = EXCEPTION_NOTIFIER['recipients']
ExceptionNotifier.sender_address = EXCEPTION_NOTIFIER['sender']
ExceptionNotifier.email_prefix = EXCEPTION_NOTIFIER['prefix']
CODE

initializer 'google.rb', <<-CODE
env = ENV['RAILS_ENV'] || RAILS_ENV
GOOGLE_KEYS = YAML.load_file(RAILS_ROOT + '/config/google.yml')[env]
CODE

initializer 'update_record_without_timestamping.rb', <<-CODE
module ActiveRecord
  class Base

    def update_record_without_timestamping(with_validation = true)
      class << self
        def record_timestamps; false; end
      end

      save(with_validation)

      class << self
        def record_timestamps; super ; end
      end
    end

  end
end
CODE

initializer 'bloatlol.rb', <<-CODE
class Object
  def not_nil?
    !nil?
  end
  
  def not_blank?
    !blank?
  end
end
CODE


route "map.root :controller => 'static', :action => 'index'"
route "map.static '/:action', :controller => 'static'"
# route "map.signup  '/signup', :controller => 'users',   :action => 'new'"
# route "map.login  '/login',  :controller => 'session', :action => 'new'"
# route "map.logout '/logout', :controller => 'session', :action => 'destroy'"
# route "map.activate '/activate/:activation_code', :controller => 'users', :action => 'activate', :activation_code => nil"
route "map.comatose_admin"
route "map.comatose_root ''"

rake("ck_fu:copy_styles")
rake("auth:gen:site_key")

git :add => '.'
git :commit => '-m "Adding in templates."'


if yes?("\nCreate and migrate databases now? (yes/no)")
  rake("db:create:all")
  rake("db:migrate")
end
