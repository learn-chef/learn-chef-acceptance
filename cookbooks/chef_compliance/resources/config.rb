include LearnChef::Compliance

property :config_file, String, required: false, default: '/etc/chef-compliance/chef-compliance.rb'
property :content, String, required: true, default: 'verify_tls false'

action :apply do
  chef_compliance_server name do
    action :nothing
  end

  file config_file do
    content 'verify_tls false'
    notifies :reconfigure, 'chef_compliance_server[default]', :immediately
    notifies :restart, 'chef_compliance_server[default]', :immediately
  end

  chef_compliance_server 'default' do
    action :nothing
  end

  chef_url = 'https://chef-compliance.local/api'
  chef = ComplianceAPI.new(server: chef_url, port: 443, ssl_insecure: true, client_name: 'admin', password: 'admin')
  puts chef.get_request('/version', '')['version']
end
