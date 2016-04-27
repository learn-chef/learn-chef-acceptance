include LearnChef::Compliance
include Chef::Mixin::ShellOut

# # this is used to name the subdirectory where the output (stdout, stderr, exit code) is written.
# property :name, String, name_property: true
# # the command to run.
# property :command, String, required: true
# # the directory to run the command.
# property :cwd, String, required: true
# # directory to write output to.
# property :cache, String, required: false, default: nil
# # the shell to run the command from. options are :bash and :powershell.
# property :shell, Symbol, required: false, default: :current
# # a Hash of environment variables to set before the command is run.
# property :environment, Hash, required: false, default: {}

# For :prepare action.

property :ip_address, String, required: false, default: node['chef_compliance']['ip_address']
property :fqdn, String, required: false, default: node['chef_compliance']['fqdn']

# For :install action.

property :package_source, String, required: false, default: 'latest'
property :package_directory, String, required: false, default: Chef::Config[:file_cache_path]

# For :setup action.

property :password, String, required: false, default: 'P4ssw0rd'
property :name, String, required: false, default: 'jsmith'
property :first_name, String, required: false, default: 'John'
property :last_name, String, required: false, default: 'Smith'
property :org, String, required: false, default: 'Chef'
property :email, String, required: false, default: 'jsmith@example.com'

def package_url()
  package_source unless package_source == 'latest'

  curl_command = case node['platform_family']
  when 'rhel'
    "curl https://downloads.chef.io/compliance/redhat/ \
    | grep availableVersions \
    | grep -o 'http[^\"]*el/#{node['platform_version'].to_i}/chef-compliance[^\"]*x86_64.rpm' \
    | head -1"
  when 'debian'
    "curl https://downloads.chef.io/compliance/ubuntu/ \
    | grep availableVersions \
    | grep -o 'http[^\"]*ubuntu/#{node['platform_version']}/chef-compliance[^\"]*amd64.deb' \
    | head -1"
  else raise "#{node['platform_family']} is not supported."
  end

  shell_out(curl_command).stdout
end

action :prepare do
  # Prepare the system
  case node['platform_family']
  when 'rhel'
    include_recipe 'selinux::permissive'
  when 'debian'
    apt_update 'Update the apt cache daily' do
      frequency 86_400
      action :periodic
    end
    package 'curl'
  end

  hostsfile_entry '127.0.0.1' do
    hostname fqdn
    unique true
  end
end

action :install do
  require 'uri'
  local_file = ::File.join(package_directory, ::File.basename(::URI.parse(package_url).path))
  remote_file local_file do
    source package_url
  end

  package ::File.basename(local_file) do
    source local_file
    notifies :run, 'execute[Reconfigure the server]', :immediately
  end

  execute 'Reconfigure the server' do
    command 'chef-compliance-ctl reconfigure && chef-compliance-ctl restart'
    action :nothing
  end
end

action :setup do
  setup_touchfile = ::File.join(Chef::Config[:file_cache_path], 'compliance-setup.touch')

  # Run setup.
  execute 'Run core setup' do
    command "/opt/chef-compliance/embedded/service/core/bin/core setup \
--password #{password} \
--name #{name} \
--accept-eula \
--firstname #{first_name} \
--lastname #{last_name} \
--org #{org} \
--email #{email} \
&& touch #{setup_touchfile}"
    not_if "ls #{setup_touchfile}"
  end
end

action :reconfigure do
  execute 'chef-compliance-ctl reconfigure'
end

action :restart do
  execute 'chef-compliance-ctl restart'
end
#
#   # Ensure working directory exists.
#   directory cwd do
#     recursive true
#   end
#
#   # Override anything mentioned in with_task_options.
#   resolved_shell = (shell == :current) ? task_options[:shell] : shell
#   resolved_environment = (environment.empty?) ? task_options[:environment] : environment
#   resolved_cache = (cache.nil?) ? task_options[:cache] : cache
#
#   # Generate final command to run.
#   case resolved_shell
#   when :bash
#     cmd = command
#   when :powershell
#     cmd = "powershell.exe -Command \"#{command}\""
#   end
#
#   # Run the command.
#   result = shell_out(cmd, cwd: cwd, environment: resolved_environment)
#
#   # Write the result to disk.
#   unless resolved_cache.nil?
#     # Ensure cache directory exists.
#     directory ::File.join(resolved_cache, name) do
#       recursive true
#     end
#
#     # Write stdout.
#     file stdout_file(resolved_cache, name) do
#       content result.stdout
#     end
#     # Write stderr.
#     file stderr_file(resolved_cache, name) do
#       content result.stderr
#     end
#     # Write exit code.
#     file status_file(resolved_cache, name) do
#       content result.exitstatus.to_s
#     end
#     # Write the command (helps with debugging).
#     file command_file(resolved_cache, name) do
#       content command
#     end
#   end
# end
