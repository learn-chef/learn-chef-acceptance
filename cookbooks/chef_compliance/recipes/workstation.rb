#
# Cookbook Name:: chef_compliance
# Recipe:: workstation
#
# Copyright (c) 2016 The Authors, All Rights Reserved.
#
# package 'curl'
# package 'tree'
#
# chef_server = search(:node, 'hostname:chef-server')[0]
# hostsfile_entry chef_server['ipaddress'] do
#   hostname chef_server['fqdn']
#   unique true
# end
#
# # Set up your workstation
#
# unless node['use_system_chef']
#   execute 'install Chef DK' do
#     command "curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -c #{node[:workflow][:packages][:chef_dk][:channel]} -P chefdk"
#     not_if 'which chef'
#   end
#
#   chefdk_version_matcher = "Chef Development Kit Version: #{node[:workflow][:packages][:chef_dk][:chefdk_version]}"
#   chef_client_version_matcher = "chef-client version: #{node[:workflow][:packages][:chef_dk][:chef_client_version]}"
#
#   control_group 'validate Chef DK installation' do
#     control 'validate version' do
#       describe command('chef --version') do
#         its (:stdout) { should match /#{Regexp.quote(chefdk_version_matcher)}/ }
#         its (:stdout) { should match /#{Regexp.quote(chef_client_version_matcher)}/ }
#       end
#     end
#   end
# end
#
# # 7. Download the Starter Kit
#
# # Instead of downloading the Starter Kit, we manually generate knife.rb and scp the client .pem from the Chef server.
#
# directory File.join(ENV['HOME'], 'learn-chef')
# directory File.join(ENV['HOME'], 'learn-chef/chef-repo')
# directory File.join(ENV['HOME'], 'learn-chef/chef-repo/.chef')
#
# file File.join(ENV['HOME'], 'learn-chef/chef-repo/.chef/knife.rb') do
#   content <<-EOH.strip_heredoc
#     # See http://docs.chef.io/config_rb_knife.html for more information on knife configuration options
#     current_dir = File.dirname(__FILE__)
#     log_level                :info
#     log_location             STDOUT
#     node_name                "jsmith"
#     client_key               "\#{current_dir}/jsmith.pem"
#     chef_server_url          "https://chef-server.local/organizations/4thcoffee"
#     cookbook_path            ["\#{current_dir}/../cookbooks"]
#   EOH
# end
#
# include_recipe 'sshpass::default'
#
# execute 'Copy client key from Chef server' do
#   # Can't get scp to do the right thing, so running ssh...
#   command "sshpass -p 'vagrant' ssh -o StrictHostKeyChecking=no root@#{chef_server['fqdn']} '( cat /root/jsmith.pem )' > #{File.join(ENV['HOME'], 'learn-chef/chef-repo/.chef/jsmith.pem')}"
#   not_if "ls #{File.join(ENV['HOME'], 'learn-chef/chef-repo/.chef/jsmith.pem')}"
# end
#
# # 8. Download the Chef server's SSL certificate
#
# execute 'Fetch Chef server SSL certificate' do
#   command 'knife ssl fetch'
#   cwd File.join(ENV['HOME'], 'learn-chef/chef-repo/.chef')
#   not_if "ls #{File.join(ENV['HOME'], 'learn-chef/chef-repo/.chef/trusted_certs/chef-server_local.crt')}"
#   notifies :run, "execute[Verify Chef server SSL certificate]", :immediately
# end
#
# execute 'Verify Chef server SSL certificate' do
#   command 'knife ssl check'
#   cwd File.join(ENV['HOME'], 'learn-chef/chef-repo/.chef')
#   action :nothing
#   notifies :run, "execute[List clients]", :immediately
# end
#
# # 9. Test the connection to Chef server
#
# execute 'List clients' do
#   command 'knife client list'
#   cwd File.join(ENV['HOME'], 'learn-chef/chef-repo/.chef')
#   action :nothing
# end
#
# # 1. Create the hello_chef_server cookbook
#
# directory File.join(ENV['HOME'], 'learn-chef/chef-repo/cookbooks')
#
# execute 'Generate hello_chef_server cookbook' do
#   command 'chef generate cookbook cookbooks/hello_chef_server'
#   cwd File.join(ENV['HOME'], 'learn-chef/chef-repo')
#   not_if "ls #{File.join(ENV['HOME'], 'learn-chef/chef-repo/cookbooks/hello_chef_server')}"
# end
#
# file File.join(ENV['HOME'], 'learn-chef/chef-repo/cookbooks/hello_chef_server/recipes/default.rb') do
#   content <<-EOH.strip_heredoc
#     file "\#{Chef::Config[:file_cache_path]}/hello.txt" do
#       content 'Hello, Chef server!'
#     end
#   EOH
# end
#
# # 2. Upload the hello_chef_server cookbook to the Chef server
#
# execute 'Upload hello_chef_server cookbook' do
#   command "knife cookbook upload hello_chef_server --config #{File.join(ENV['HOME'], 'learn-chef/chef-repo/.chef/knife.rb')}"
#   cwd File.join(ENV['HOME'], 'learn-chef/chef-repo')
#   not_if "knife cookbook list --config #{File.join(ENV['HOME'], 'learn-chef/chef-repo/.chef/knife.rb')} | grep hello_chef_server", :cwd => File.join(ENV['HOME'], 'learn-chef/chef-repo')
#   notifies :run, "execute[List cookbooks]", :immediately
# end
#
# execute 'List cookbooks' do
#   command "knife cookbook list --config #{File.join(ENV['HOME'], 'learn-chef/chef-repo/.chef/knife.rb')}"
#   cwd File.join(ENV['HOME'], 'learn-chef/chef-repo')
#   action :nothing
# end
#
# # 4. Bootstrap your node
#
# node_1 = search(:node, 'hostname:node-1')[0]
# execute 'Bootstrap the node' do
#   command "knife bootstrap #{node_1['ipaddress']} --ssh-user root --sudo --ssh-password vagrant --node-name node1 --run-list 'recipe[hello_chef_server]' --config #{File.join(ENV['HOME'], 'learn-chef/chef-repo/.chef/knife.rb')}"
#   cwd File.join(ENV['HOME'], 'learn-chef/chef-repo')
#   not_if "knife node list --config #{File.join(ENV['HOME'], 'learn-chef/chef-repo/.chef/knife.rb')} | grep node1", :cwd => File.join(ENV['HOME'], 'learn-chef/chef-repo')
#   notifies :run, "execute[Verify result]", :immediately
# end
#
# # 5. Confirm the result
#
# execute 'Verify result' do
#   command "knife ssh #{node_1['ipaddress']} 'more /var/chef/cache/hello.txt' --manual-list --ssh-user root --ssh-password vagrant --config #{File.join(ENV['HOME'], 'learn-chef/chef-repo/.chef/knife.rb')}"
#   cwd File.join(ENV['HOME'], 'learn-chef/chef-repo')
#   action :nothing
# end
