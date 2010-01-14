application = ask("\nWhat is your application called? (NO SPACES!!)")
ssh_user = ask("\nWhich SSH user is used on your remote?")

run "rm public/index.html"
run "rm public/images/rails.png"
run "rm README"
run "cp config/database.yml config/database.yml.example"

file '.gitignore', 
%q{
.DS_Store
.dotest/*
coverage/*
db/*.db
doc/api
doc/app
log/*.log
log/*.pid
public/javascripts/all.js
public/stylesheets/all.js
tmp/**/*
tmp/restart.txt
config/database.yml
db/*.sqlite3
}

git :init
git :add => "."
git :commit => '-m "Initial commit Template."'

plugin 'acts_as_list', :git => "git://github.com/rails/acts_as_list.git"
plugin 'acts_as_tree', :git => "git://github.com/rails/acts_as_tree.git"
plugin 'exception_notification', :git => "git://github.com/rails/exception_notification.git"
plugin 'ck_fu', :git => "git://github.com/r38y/ck_fu.git"

git :add => "."
git :commit => '-m "Added plugins"'

plugin 'rspec', :git => "git://github.com/dchelimsky/rspec.git"
plugin 'rspec-rails', :git => "git://github.com/dchelimsky/rspec-rails.git"
plugin 'factory_girl', :git => "git://github.com/thoughtbot/factory_girl.git"
plugin 'cucumber', :git => "git://github.com/aslakhellesoy/cucumber.git"

generate("rspec")

git :add => "."
git :commit => '-m "Added plugins for TDD/BDD"'

file 'app/controllers/application_controller.rb', <<-RUBY
class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  include ExceptionNotifiable
  
  # Scrub sensitive parameters from your log
  filter_parameter_logging :password
end
RUBY

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

file 'app/views/layouts/application.html.erb', <<-TEMPLATE
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">

<html lang="en">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <title>#{application}</title>
</head>
<body>
  <%- flash.each do |name, msg| -%>
    <%= content_tag :div, msg, :class => name %>
  <%- end -%>
  <%= yield %>
</body>
</html>
TEMPLATE

generate('rspec_controller', 'static')

file 'app/views/static/index.html.erb', <<-TEMPLATE
<p>
  You have successfully created a basic application! 
</p>
TEMPLATE

file 'app/controllers/static_controller.rb', <<-RUBY
class StaticController < ApplicationController
  def index
  end
end
RUBY

git :add => '.'
git :commit => '-m "Adding ApplicationController, Layouts and CSS."'

file 'config/deploy.rb', <<-RUBY
set :stages, %w(staging production)
set :default_stage, "staging"
require 'capistrano/ext/multistage'

set :application, "#{application}"
set :scm, :git
default_run_options[:pty] = true
set :repository, "git@github.com:LeipeLeon/\#\{application}.git"

set :repository_cache, "git_master"
set :deploy_via, :remote_cache
set :branch, "master"
set :scm_verbose, :true
set :keep_releases, 3

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
    run "if [ ! -d \\\"\#\{deploy_to}/\#\{shared_dir}/config\\\" ] ; then mkdir \#\{deploy_to}/\#\{shared_dir}/config ; fi"
  end

  after "deploy:finalize_update", "deploy:symlink_config"
  desc "Link to database.yml in shared/config" 
  task :symlink_config do
    ['database'].each {|yml_file|
      # remove  the git version of yml_file.yml
      run "if [ -e \\\"\#\{release_path}/config/\#\{yml_file}.yml\\\" ] ; then rm \#\{release_path}/config/\#\{yml_file}.yml; fi"
    
      # als shared conf bestand nog niet bestaat
      run "if [ ! -e \\\"\#\{deploy_to}/\#\{shared_dir}/config/\#\{yml_file}.yml\\\" ] ; then cp \#\{deploy_to}/\#\{shared_dir}/\#\{repository_cache}/config/\#\{yml_file}.example.yml \#\{deploy_to}/\#\{shared_dir}/config/\#\{yml_file}.yml; fi"
    
      # link to the shared yml_file.yml
      run "ln -nfs \#\{deploy_to}/\#\{shared_dir}/config/\#\{yml_file}.yml \#\{release_path}/config/\#\{yml_file}.yml" 
    }
    # set deployment date
    run "date > \#\{current_release}/DATE"
  end

  after "deploy:symlink", "deploy:update_crontab"
  desc "Update the crontab file"
  task :update_crontab, :roles => :db do
    run "cd \#\{release_path} && whenever --update-crontab \#\{application}"
  end


  desc "Set .htacces to RailsEnv staging"
  task :update_htaccess, :roles => :app do
    run "echo 'RailsEnv staging' > \#\{current_path}/public/.htaccess"
  end
  
  # desc "Copy system directory from live site to local"
  # task :copy_system do
  #   run "rsync -avz /home/sneaker/apps/\#\{application}/\#\{shared_dir}/system/ \#\{deploy_to}/\#\{shared_dir}/system/"
  # end
end

namespace :db do
  require 'yaml'
  
  def mysql_dump(environment, file)
    dbp = YAML::load(ERB.new(IO.read(File.join(File.dirname(__FILE__), 'database.yml'))).result)[environment]
    run "mysqldump -u \#\{dbp['username']} --password=\#\{dbp['password']} \#\{dbp['database']} | bzip2 -c > \#\{file}"  do |ch, stream, out|
      puts out
    end
  end
  
  desc "Copy production db to the staging db" 
  task :copy_production_to_staging, :roles => :db, :only => { :primary => true } do
    filename = "\#\{application}.dump.\#\{Time.now.to_i}.sql.bz2" 
    file = "/tmp/\#\{filename}" 
    on_rollback { delete file }
    
    # Dump production
    mysql_dump('production', file)
    
    # load in staging
    dbs = YAML::load(ERB.new(IO.read(File.join(File.dirname(__FILE__), 'database.yml'))).result)['staging']
    logger.debug "delete all tables in staging database" 
    run "mysqldump -u \#\{dbs['username']} --password=\#\{dbs['password']} --add-drop-table --no-data \#\{dbs['database']} | grep ^DROP | mysql -u \#\{dbs['username']} --password=\#\{dbs['password']} \#\{dbs['database']}"
    logger.debug "Loading \#\{filename} into staging database" 
    run "bzip2 -cd \#\{file} | mysql -u \#\{dbs['username']} --password=\#\{dbs['password']} \#\{dbs['database']}"
    
    run "rm \#\{file}" 
    
    # run "rsync -avz /home/sneaker/apps/\#\{application}/\#\{shared_dir}/system/ \#\{deploy_to}/\#\{shared_dir}/system/"
  end

  desc "Backup the production db to local filesystem" 
  task :backup_to_local, :roles => :db, :only => { :primary => true } do
    filename = "\#\{application}.dump.\#\{Time.now.to_i}.sql.bz2" 
    file = "/tmp/\#\{filename}" 
    on_rollback { delete file }
    
    # Dump production
    mysql_dump('production', file)
    
    `mkdir -p \#\{File.dirname(__FILE__)}/../backups/`
    get file, "backups/\#\{filename}" 
    run "rm \#\{file}" 
  end

  desc "Copy the latest backup to the local development database" 
  task :import_backup do
    filename = `ls -tr backups | tail -n 1`.chomp
    if filename.empty?
      logger.important "No backups found" 
    else
      ddb = YAML::load(ERB.new(IO.read(File.join(File.dirname(__FILE__), 'database.yml'))).result)['development']
      logger.debug "delete all tables in development database" 
      `mysqldump -u \#\{ddb['username']} --password=\#\{ddb['password']} --add-drop-table --no-data \#\{ddb['database']} | grep ^DROP | mysql -u \#\{ddb['username']} --password=\#\{ddb['password']} \#\{ddb['database']}`
      logger.debug "Loading backups/\#\{filename} into local development database" 
      `bzip2 -cd backups/\#\{filename} | mysql -u \#\{ddb['username']} --password=\#\{ddb['password']} \#\{ddb['database']}`
      logger.debug "Running migrations" 
      `rake db:migrate`
      # logger.debug "Syncing assets to local machine" 
      # `rake assets:sync`
    end
  end

  desc "Backup the remote production database to local filesystem and import it to the local development database" 
  task :backup_and_import do
    backup_to_local
    import_backup
  end
end
RUBY

file 'config/deploy/production.rb', <<-RUBY
role :app, "#{ssh_user}"
role :web, "#{ssh_user}"
role :db,  "#{ssh_user}", :primary => true
set :user, '#{ssh_user}'
set :rails_env, 'production'
set :deploy_to, "/home/\#\{user}/apps/\#\{application}"
RUBY

file 'config/deploy/staging.rb', <<-RUBY
role :app, "#{ssh_user}"
role :web, "#{ssh_user}"
role :db,  "#{ssh_user}", :primary => true
set :user, '#{ssh_user}'
set :rails_env, 'staging'
set :deploy_to, "/home/\#\{user}/apps/\#\{application}_staging"
set :keep_releases, 1
RUBY

file 'config/exception.yml', <<-YAML
development:
    recipients: leonb@beriedata.nl
    sender: '"Leon Berenschot" <leonb@beriedata.nl>'
    prefix: "[#{application} Devel] "
test:
    recipients: leonb@beriedata.nl
    sender: '"Leon Berenschot" <leonb@beriedata.nl>'
    prefix: "[#{application} Test] "
cucumber:
    recipients: leonb@beriedata.nl
    sender: '"Leon Berenschot" <leonb@beriedata.nl>'
    prefix: "[#{application} Cucumber] "
staging:
    recipients: leonb@beriedata.nl
    sender: '"Leon Berenschot" <leonb@beriedata.nl>'
    prefix: "[#{application} Staging] "
production:
    recipients: leonb@beriedata.nl
    sender: '"Leon Berenschot" <leonb@beriedata.nl>'
    prefix: "[#{application}] "
YAML

file 'config/google.yml', <<-YAML
production:
    analytics: ""
staging: 
    analytics: ""
development: 
    analytics: ""
YAML

file 'app/helpers/google_helper.rb', <<-RUBY
module GoogleHelper
  def google_analytics
    if GOOGLE_KEYS['analytics'] != ''
      '<script type="text/javascript">
      var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
      document.write(unescape("%3Cscript src=\\\'" + gaJsHost + "google-analytics.com/ga.js\\\' type=\\\'text/javascript\\\'%3E%3C/script%3E"));
      </script>
      <script type="text/javascript">
      try {
      var pageTracker = _gat._getTracker("' + GOOGLE_KEYS['analytics'] + '");
      pageTracker._trackPageview();
      } catch(err) {}</script>'
    end
  end
end
RUBY

file 'config/email_settings.yml', <<-YAML
development:
  host: http://#{application}.local
  sender: Development <leonb@beriedata.nl>
  subject: "[#{application} Devel] "

test:
  host: http://#{application}.local
  sender: Test <leonb@beriedata.nl>
  subject: "[#{application} Test] "

staging:
  host: http://office.beriedata.nl/#{application}
  sender: Staging <leonb@beriedata.nl>
  subject: "[#{application} Staging] "

production:
  host: http://#{application}.com
  sender: #{application} <info@#{application}.com>
  subject: "[#{application}] "
YAML

file 'Capfile', <<-RUBY
load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
load 'config/deploy'
RUBY

# run "cp config/twitter_auth.yml config/twitter_auth.yml.example"
git :add => '.'
git :commit => '-m "Adding Deployment and Settings."'

# Download JQuery
run "curl -L http://jqueryjs.googlecode.com/files/jquery-1.2.6.min.js > public/javascripts/jquery.js"
run "curl -L http://jqueryjs.googlecode.com/svn/trunk/plugins/form/jquery.form.js > public/javascripts/jquery.form.js"

git :add => '.'
git :commit => '-m "Adding JQuery."'

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

initializer 'ar_read_only_check_before_destroy.rb', <<-CODE
# http://blog.zobie.com/2009/01/read-only-models-in-activerecord/
module ActiveRecord
  class Base
    def before_destroy
      super
      raise ActiveRecord::ReadOnlyRecord if readonly?
    end
  end
end
CODE

initializer 'am_i18n_action_mailer.rb', <<-CODE
# http://github.com/Bertg/i18n_action_mailer
module I18nActionMailer

  def self.included(base)
    base.send :include, I18nActionMailer::InstanceMethods
    base.helper_method :locale, :t, :translate, :l, :localize
  end

  module InstanceMethods
    def translate(key, options = {})
      I18n.translate(key, options.merge(:locale => self.locale))
    end
    alias_method :t, :translate

    def localize(key, options = {})
      I18n.localize(key, options.merge(:locale => self.locale))
    end
    alias_method :l, :localize

    def locale
      @locale
    end

    def set_locale(locale)
      @locale = locale
    end
  end

end

ActionMailer::Base.send(:include, I18nActionMailer)
CODE
initializer 'ar_update_record_without_timestamping.rb', <<-CODE
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

# lib 'rails.rb', <<-CODE
# module Rails
#   class TemplateRunner
#     # Adds a line inside the ApplicationController
#     def application_controller(data = nil, options = {}, &block)
#       sentinel = 'class ApplicationController < ActionController::Base'
#       
#       data = block.call if !data && block_given?
#       
#       in_root do
#         gsub_file 'app/controllers/application_controller.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
#           "#{match}\n  " << data
#         end
#       end
#     end
#   end
# end
# CODE

git :add => '.'
git :commit => '-m "Adding Initializers."'

rake("ck_fu:copy_styles")
rake("auth:gen:site_key")

git :add => '.'
git :commit => '-m "Executed RakeTask."'

generate('controller', 'static')

file 'app/views/static/index.html.erb', <<-TEMPLATE
<h2>Welcome to Your Application!</h2>

<p>
  You have successfully created a Twitter-ready application! To test it out just click on <strong>Login via Twitter</strong> above. You should be taken to Twitter and then back here where it will tell you that you are logged in!
</p>

<p>
  This template doesn''t assume anything about how you want to build your application other than that you want to use Twitter authentication to do it, so you can generate any controllers, models, and anything else you like! You can tie it back to Twitter accounts simply by adding associations etc. to <code>app/models/user.rb</code>.
</p>

<% if @users.any? %>
  <h2>Recently Joined</h2>
  <% for user in @users %>
    <%= link_to profile_image(user), twitter_profile_url(user), :target => "_blank" %>
  <% end %>
<% end %>
TEMPLATE




if yes?("\nCreate and migrate databases now? (yes/no)")
  rake("db:create:all")
  rake("db:migrate")
end

if yes?("\nRun rake gems:install? (yes/no)")
  rake("gems:install", :sudo => true)
end
