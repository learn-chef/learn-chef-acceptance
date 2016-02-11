#
# Cookbook Name:: learn-the-basics-ubuntu
# Recipe:: setup
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
include_recipe 'apt::default'
package 'curl'
package 'tree'

chefdk_version = '0.11.0'
chef_client_version = '12.7.0'

execute 'install Chef DK' do
  command 'curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -c current -P chefdk'
  not_if 'which chef'
end

control_group 'validate Chef DK installation' do
  # control 'validate version' do
  #   describe command('chef --version') do
  #     its (:stdout) { should match /Chef Development Kit Version: #{chefdk_version}/ }
  #     its (:stdout) { should match /chef-client version: #{chef_client_version}/ }
  #   end
  # end

  control 'validate successful run' do
    describe command('chef verify') do
      its (:stdout) { should match /Verification of .+ succeeded/ }
      its (:stdout) { should_not match /Verification of .+ failed/ }
    end
  end
end
