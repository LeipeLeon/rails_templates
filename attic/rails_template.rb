# rails -m http://github.com/mbleigh/rails-templates/raw/master/twitterapp.rb yourappname
# Twitter App Generator
# by Michael Bleigh
#
# Build the complete skeleton for a Twitter application using
# TwitterAuth. This generator will automatically build the
# basics for an OAuth-based Twitter application and will prompt
# you for your OAuth credentials.

app_name = ask("\nWhat is your application called?")

# puts "\nBefore this generator runs you will need to register two Twitter applications for OAuth at http://twitter.com/apps. One will be for development (enter the callback as http://localhost.com:3000/oauth_callback) and the other for production (enter your production URL and callback).
# 
# Once finished, enter the consumer keys and secrets when prompted below:\n"
# 
# dev_consumer_key = ask("\nDevelopment OAuth Consumer Key:")
# dev_consumer_secret = ask("\nDevelopment OAuth Consumer Secret:")
# prod_consumer_key = ask("\nProduction OAuth Consumer Key:")
# prod_consumer_secret = ask("\nProduction OAuth Consumer Secret:")

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

# gem 'thoughtbot-shoulda', :source => "http://gems.github.com"
gem 'haml', :version => '>= 2.0.6' # for SASS
# gem "oauth", :version => '>=0.3.4'
# gem "json"
# gem "twitter", :version => '>=0.6.11'
# gem "chronic", :version => ">=0.2.3"
gem "javan-whenever", :lib => false, :source => "http://gems.github.com"
# gem "icalendar", :version => ">=1.1.0"
# gem 'mislav-will_paginate', :version => '~> 2.2.3', :lib => 'will_paginate',  :source => 'http://gems.github.com'
# gem 'twitter-auth', :lib => 'twitter_auth'

git :add => "."
git :commit => '-m "Added gems"'

# plugin 'paperclip', :git => "git://github.com/thoughtbot/paperclip.git"
# plugin 'restful_authentication', :git => "git://github.com/technoweenie/restful-authentication.git"
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
plugin 'invoicing', :git => 'git://github.com/ept/invoicing.git'
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

file 'app/views/layouts/master.html.erb', <<-TEMPLATE
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8"/>
    <title>#{app_name} - <%= @title || "Powered by TwitterAuth" %></title>
    <%= stylesheet_link_tag 'master', 'ck_fu' %>
    <%= javascript_include_tag :defaults %>
  </head>
  <body>
    <div id='wrapper'>
      <div id='header'>
        <h1><%= link_to '#{app_name}', '/' %></h1>
         
        <div id='user_bar'>
          <% if logged_in? %>
            <%= image_tag(current_user.profile_image_url, :width => 24, :height => 24) %> Logged in as <strong>@<%= current_user.login %></strong>. <%= link_to 'Log out', '/logout' %>
          <% else %>
            <%= link_to 'Login via Twitter', '/login' %>
          <% end %>
        </div>
        <div class='clearfix'></div>
      </div>
      <div id='contents'>
        <% if flash[:error] %>
          <div class='flash error'><%= flash[:error] %></div>
        <% end %><% if flash[:notice] %>
          <div class='flash notice'><%= flash[:notice] %></div>
        <% end %>
        <%= yield %>
      </div>
    </div>
    <div id='footer'>
      Copyright &copy; 2009 #{app_name}. Powered by <%= link_to 'TwitterAuth', 'http://mbleigh.com/twitter-auth', :target => '_blank' %>.
    </div>
  </body>
</html>
TEMPLATE

file 'app/views/static/index.html.erb', <<-TEMPLATE
<h2>Welcome to Your Twitter Application!</h2>

<p>You have successfully created a Twitter-ready application! To test it out just click on <strong>Login via Twitter</strong> above. You should be taken to Twitter and then back here where it will tell you that you are logged in!</p>

<p>This template doesn't assume anything about how you want to build your application other than that you want to use Twitter authentication to do it, so you can generate any controllers, models, and anything else you like! You can tie it back to Twitter accounts simply by adding associations etc. to <code>app/models/user.rb</code>.</p><!-- ' -->

<% if @users.any? %>
  <h2>Recently Joined</h2>
  <% for user in @users %>
    <%= link_to profile_image(user), twitter_profile_url(user), :target => "_blank" %>
  <% end %>
<% end %>
TEMPLATE

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
  layout 'master'
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
role :app, "office.beriedata.nl"
role :web, "office.beriedata.nl"
role :db,  "office.beriedata.nl", :primary => true
set :user, 'root'
set :rails_env, 'staging'
set :deploy_to, "/var/www/apps/\#\{application}"
RUBY

file 'app/controllers/static_controller.rb', <<-RUBY
class StaticController < ApplicationController
  def index
    @users = User.all(:order => "created_at DESC", :limit => 16)
  end
end
RUBY

file 'app/helpers/twitter_helper.rb', <<-RUBY
module TwitterHelper
  def twitter_profile_url(user)
    "http://twitter.com/\#{user.login}"
  end

  def twitter_name(user)
    "@\#{user.login}"
  end

  def profile_image(user, options = {})
    alt = "\#{user.name} (@\#{user.login})"
    image_tag(user.profile_image_url, :alt => alt, :title => alt)
  end
end
RUBY

# file 'config/twitter_auth.yml', <<-YAML
# development:
#   strategy: oauth
#   oauth_consumer_key: "#{dev_consumer_key}"
#   oauth_consumer_secret: "#{dev_consumer_secret}"
#   base_url: "http://twitter.com"
#   authorize_path: "/oauth/authenticate"
#   api_timeout: 10
#   remember_for: 14 # days
#   oauth_callback: "http://#{app_name}.local/oauth_callback"
# test:
#   strategy: oauth
#   oauth_consumer_key: "#{dev_consumer_key}"
#   oauth_consumer_secret: "#{dev_consumer_secret}"
#   authorize_path: "/oauth/authenticate"  
#   base_url: "http://twitter.com"
#   api_timeout: 10
#   remember_for: 14 # days
#   oauth_callback: "http://#{app_name}.local/oauth_callback"
# production:
#   strategy: oauth
#   oauth_consumer_key: "#{prod_consumer_key}"
#   oauth_consumer_secret: "#{prod_consumer_secret}"
#   authorize_path: "/oauth/authenticate"  
#   base_url: "http://twitter.com"
#   api_timeout: 10
#   remember_for: 14 # days
# YAML

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
