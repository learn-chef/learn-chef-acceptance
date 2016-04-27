#
# Cookbook Name:: chef_compliance_assess
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

# Add Compliance server to hosts file.
chef_compliance = search(:node, 'hostname:chef-compliance')[0]
hostsfile_entry chef_compliance['ipaddress'] do
  hostname chef_compliance['fqdn']
  unique true
end

# # Create a user.
# chef_compliance_user 'admin' do
#   full_name "John Smith"
# end
#
# chef_compliance_user 'suzy' do
#   full_name "Suzy Smith"
# end
#
# # Create an environment.
# chef_compliance_env 'admin/Development' do
# end
#
# # TODO: Use PK
#
# # Create a node.
# # chef_compliance_node 'admin/Development/node1' do
# #   hostname "192.168.77.78"
# #   login_password "vagrant"
# # end
#
# # Scan the node against the built-in CIS profile.
# chef_compliance_scan 'base/linux' do
#   environment 'e357c111-4287-441c-43fe-25c15a13e1ee/Development'
#   node_name 'node1'
# end
