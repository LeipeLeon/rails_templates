# Install submoduled plugins
plugin 'open_id_authentication',  :git => 'git://github.com/rails/open_id_authentication.git', :submodule => true
plugin 'role_requirement',        :git => 'git://github.com/timcharper/role_requirement.git', :submodule => true
plugin 'restful-authentication',  :git => 'git://github.com/technoweenie/restful-authentication.git', :submodule => true
plugin 'acts_as_taggable_redux',  :git => 'git://github.com/geemus/acts_as_taggable_redux.git', :submodule => true
plugin 'aasm',                    :git => 'git://github.com/rubyist/aasm.git', :submodule => true

# Set up sessions, RSpec, user model, OpenID, etc, and run migrations
rake('db:sessions:create')
generate("authenticated", "user session")
generate("roles", "Role User")

git :submodule => "init"

rake('acts_as_taggable:db:create')
rake('open_id_authentication:db:create')

git :add => "."
git :commit => "-m 'Added Auth Template'"

if yes?("\nMigrate databases now? (yes/no)")
  rake("db:migrate")
end

if yes?("\nRun rake gems:install? (yes/no)")
  rake("gems:install", :sudo => true)
end
