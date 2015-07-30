set :stage, :vmware
set :branch, 'vmware-demo'
set :rails_env, 'staging'

# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary
# server in each group is considered to be the first
# unless any hosts have the primary property set.
# Don't declare `role :all`, it's a meta role
role :app, ["deploy@#{ENV['VMWARE_SERVER1_IP']}", "deploy@#{ENV['VMWARE_SERVER2_IP']}"]
role :web, ["deploy@#{ENV['VMWARE_SERVER1_IP']}", "deploy@#{ENV['VMWARE_SERVER2_IP']}"]
role :db,  ["deploy@#{ENV['VMWARE_SERVER1_IP']}"]

# you can set custom ssh options
# it's possible to pass any option but you need to keep in mind that net/ssh understand limited list of options
# you can see them in [net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start)
# set it globally
set :ssh_options, forward_agent: true

# and/or per server
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
# setting per server overrides global ssh_options
