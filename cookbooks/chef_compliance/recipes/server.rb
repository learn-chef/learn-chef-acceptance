#
# Cookbook Name:: chef_compliance
# Recipe:: server
#
# Copyright (c) 2016 The Authors, All Rights Reserved.
#
# # 1. Prepare a system to run Chef server
# case node['platform']
# when 'centos'
#   include_recipe 'selinux::permissive'
#
#   execute 'Disable Apache Qpid' do
#     command <<-EOH.strip_heredoc
#       service qpidd stop
#       chkconfig --del qpidd
#     EOH
#     only_if 'rpm -qa | grep qpid'
#   end
# when 'ubuntu'
#   # TODO
# end
#
# # 2. Install Chef server
#
# package_attributes = node['chef_compliance']['server'][node['platform']]
#
# # We use standard commands and not Chef to mimic what the user does.
# case node['platform']
# when 'centos'
#   execute 'Download and install the Chef server package' do
#     command <<-EOH.strip_heredoc
#       sudo yum install wget -y
#       wget #{package_attributes['url_prefix']}#{package_attributes['package']}
#       sudo rpm -Uvh #{package_attributes['package']}
#     EOH
#     not_if 'which chef-server-ctl'
#   end
# when 'ubuntu'
#   # TODO
# end
#
# # 3. Write the Chef server configuration file
#
# file '/etc/opscode/chef-server.rb' do
#   content <<-EOH.strip_heredoc
#     server_name = "#{node['fqdn']}"
#     api_fqdn server_name
#     bookshelf['vip'] = server_name
#     nginx['url'] = "https://\#{server_name}"
#     nginx['server_name'] = server_name
#     nginx['ssl_certificate'] = "/var/opt/opscode/nginx/ca/\#{server_name}.crt"
#     nginx['ssl_certificate_key'] = "/var/opt/opscode/nginx/ca/\#{server_name}.key"
#   EOH
#   notifies :run, "execute[Reconfigure Chef server]", :immediately
# end
#
# # 4. Apply the configuration and start the server
#
# execute 'Reconfigure Chef server' do
#   command 'sudo chef-server-ctl reconfigure'
#   action :nothing
# end
#
# # 5. Install the management console and reporting features
#
# execute 'Install Chef Manage' do
#   command <<-EOH.strip_heredoc
#     sudo chef-server-ctl install chef-manage
#     sudo chef-server-ctl reconfigure
#     sudo chef-manage-ctl reconfigure
#   EOH
#   not_if 'which chef-manage-ctl'
# end
#
# execute 'Install Reporting' do
#   command <<-EOH.strip_heredoc
#     sudo chef-server-ctl install opscode-reporting
#     sudo chef-server-ctl reconfigure
#     sudo opscode-reporting-ctl reconfigure
#   EOH
#   not_if 'which opscode-reporting-ctl'
# end
#
# # 6. Create the administrator account and an organization
#
# execute 'Create the admin account' do
#   command 'sudo chef-server-ctl user-create jsmith Joe Smith joe.smith@example.com p4ssw0rd --filename /root/jsmith.pem'
#   not_if 'sudo chef-server-ctl user-list | grep jsmith'
# end
#
# execute 'Create the organization' do
#   command 'sudo chef-server-ctl org-create 4thcoffee "Fourth Coffee, Inc." --association_user jsmith'
#   not_if 'sudo chef-server-ctl org-list | grep 4thcoffee'
# end
