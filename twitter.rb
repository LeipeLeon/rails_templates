puts "\nBefore this generator runs you will need to register two Twitter applications for OAuth at http://twitter.com/apps. One will be for development (enter the callback as http://localhost.com:3000/oauth_callback) and the other for production (enter your production URL and callback).

Once finished, enter the consumer keys and secrets when prompted below:\n"

dev_consumer_key = ask("\nDevelopment OAuth Consumer Key:")
dev_consumer_secret = ask("\nDevelopment OAuth Consumer Secret:")
prod_consumer_key = ask("\nProduction OAuth Consumer Key:")
prod_consumer_secret = ask("\nProduction OAuth Consumer Secret:")


gem 'haml', :version => '>= 2.0.6'
gem 'oauth', :version => '>= 0.3.1'
gem 'twitter-auth', :lib => 'twitter_auth'

generate('twitter_auth')

file 'app/views/static/index.html.erb', <<-TEMPLATE
<h2>Welcome to Your Twitter Application!</h2>

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

run "cp config/twitter_auth.yml config/twitter_auth.yml.example"

file 'config/twitter_auth.yml', <<-YAML
development:
  strategy: oauth
  oauth_consumer_key: "#{dev_consumer_key}"
  oauth_consumer_secret: "#{dev_consumer_secret}"
  base_url: "http://twitter.com"
  authorize_path: "/oauth/authenticate"
  api_timeout: 10
  remember_for: 14 # days
  oauth_callback: "http://localhost:3000/oauth_callback"
test:
  strategy: oauth
  oauth_consumer_key: "#{dev_consumer_key}"
  oauth_consumer_secret: "#{dev_consumer_secret}"
  authorize_path: "/oauth/authenticate"  
  base_url: "http://twitter.com"
  api_timeout: 10
  remember_for: 14 # days
  oauth_callback: "http://localhost:3000/oauth_callback"
production:
  strategy: oauth
  oauth_consumer_key: "#{prod_consumer_key}"
  oauth_consumer_secret: "#{prod_consumer_secret}"
  authorize_path: "/oauth/authenticate"  
  base_url: "http://twitter.com"
  api_timeout: 10
  remember_for: 14 # days
YAML

git :add => '.'
git :commit => '-m "Adding in templates and plugins for Twitter RailsTemplate."'

# if yes?("\nRun rake gems:install? (yes/no)")
  rake("gems:install")
# end

# if yes?("\nMigrate databases now? (yes/no)")
  rake("db:migrate")
# end