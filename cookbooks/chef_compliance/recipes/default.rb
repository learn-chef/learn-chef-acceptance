#
# Cookbook Name:: chef_compliance
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.
#
chef_gem 'httparty' do
  compile_time false
end

#api_version('', 'admin', 'admin')

# file '/etc/app.conf' do
#   content <<-EOH
#     #{Chef::HTTP.new('https://chef-compliance.local/api').get('/version')}
#   EOH
# end

# http_request "Get version" do
#   action :post
#   url "https://chef-compliance.local/api/version"
# end

chef_compliance_server 'default' do
  action [:prepare, :install, :setup]
end

chef_compliance_config 'default' do
  action :apply
end



# bash 'blah' do
#   code <<-EOH
#     API_URL="https://chef-compliance.local/api"
#     USERNAME1="admin"
#     PASSWORD="admin"
#     JSON=$(curl --insecure -s -S -X POST "$API_URL/oauth/token" -u "$USERNAME1:$PASSWORD" -d "grant_type=client_credentials")
#     API_KEY=$(echo $JSON | sed -e "s/.*access_token\":\"\([^\"]*\)\".*/\1/")
#     curl --insecure -X GET "$API_URL/users" -u "$API_KEY:"
#   EOH
# end

# # Set configuration.
# file '/etc/chef-compliance/chef-compliance.rb' do
#   content 'verify_tls false'
#   notifies :run, "execute[Reconfigure Chef Compliance]", :immediately
# end

# setup_touchfile = File.join(ENV['HOME'], 'setup.touch')
#
# # Run setup.
# execute "Run core setup" do
#   command "sudo /opt/chef-compliance/embedded/service/core/bin/core setup --password P4ssw0rd --name tpetchel --accept-eula --firstname Thomas --lastname Petchel --org Chef --email tpetchel@chef.io && touch #{setup_touchfile}"
#   not_if "ls #{setup_touchfile}"
#   notifies :run, "execute[Reconfigure Chef Compliance]", :immediately
# end
#
#
# # Set configuration.
# file '/etc/chef-compliance/chef-compliance.rb' do
#   content 'verify_tls false'
#   notifies :run, "execute[Reconfigure Chef Compliance]", :immediately
# end

# # Restart the server.
# execute 'Reconfigure Chef Compliance' do
#   command 'sudo chef-compliance-ctl reconfigure && sudo chef-compliance-ctl restart'
#   action :nothing
# end
#
#
# # Prepare the system to run Chef Compliance.
# case node['platform']
# when 'centos'
#   include_recipe 'selinux::permissive'
# when 'ubuntu'
#   # TODO
# end
#
# # Install Chef Compliance.
# package_attributes = node['chef_compliance']['server'][node['platform']]
#
# # We use standard commands and not Chef to mimic what the user does.
# case node['platform']
# when 'centos'
#   execute 'Download and install Chef Compliance package' do
#     command <<-EOH.strip_heredoc
#       sudo yum install wget -y
#       wget #{package_attributes['url_prefix']}#{package_attributes['package']}
#       sudo rpm -Uvh #{package_attributes['package']}
#     EOH
#     not_if 'which chef-compliance-ctl'
#     notifies :run, "execute[Reconfigure Chef Compliance]", :immediately
#   end
# when 'ubuntu'
#   # TODO
# end
#
# setup_touchfile = File.join(ENV['HOME'], 'setup.touch')
#
# # Run setup.
# execute "Run core setup" do
#   command "sudo /opt/chef-compliance/embedded/service/core/bin/core setup --password P4ssw0rd --name tpetchel --accept-eula --firstname Thomas --lastname Petchel --org Chef --email tpetchel@chef.io && touch #{setup_touchfile}"
#   not_if "ls #{setup_touchfile}"
#   notifies :run, "execute[Reconfigure Chef Compliance]", :immediately
# end
#
#
# # Set configuration.
# file '/etc/chef-compliance/chef-compliance.rb' do
#   content 'verify_tls false'
#   notifies :run, "execute[Reconfigure Chef Compliance]", :immediately
# end
