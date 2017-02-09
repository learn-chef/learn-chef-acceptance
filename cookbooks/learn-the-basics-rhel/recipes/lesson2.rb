#
# Cookbook Name:: learn-the-basics-rhel
# Recipe:: lesson2
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
#---
# Configure a package and service
#---

working = File.join(ENV['HOME'], 'chef-repo')
cache = File.join(ENV['HOME'], '.acceptance/configure-a-package-and-service')

workflow_task_options 'Configure a package and service' do
  shell :bash
  cache cache
end

directory working do
  action [:delete, :create]
  recursive true
end

#---
# 1. Install the Apache package
#---

# Write webserver.rb.
file File.join(working, 'webserver.rb') do
  content <<-EOF.strip_heredoc
    package 'httpd'
  EOF
end

# Run chef-client.
workflow_task '2.1.1' do
  cwd working
  command 'sudo chef-client --local-mode webserver.rb --no-color --force-formatter --log_level warn'
end

# Run chef-client again.
workflow_task '2.1.2' do
  cwd working
  command 'sudo chef-client --local-mode webserver.rb --no-color --force-formatter --log_level warn'
end

f2_1_1 = stdout_file(cache, '2.1.1')
f2_1_2 = stdout_file(cache, '2.1.2')
control_group '2.1' do
  control 'validate output' do
    describe file(f2_1_1) do
      [
        /WARN: No config file/,
        /WARN: No cookbooks directory/,
        /Converging 1 resources/,
        /\* yum_package\[httpd\] action install/,
        /Chef Client finished, 1/
      ].each do |matcher|
        its(:content) { should match matcher }
      end
    end
    describe file(f2_1_2) do
      its(:content) { should match /yum_package\[httpd\] action install \(up to date\)/ }
    end
  end
end

#---
# 2. Start and enable the Apache service
#---

# Write webserver.rb.
file File.join(working, 'webserver.rb') do
  content <<-EOF.strip_heredoc
    package 'httpd'

    service 'httpd' do
      action [:enable, :start]
    end
  EOF
end

# Run chef-client.
workflow_task '2.2.1' do
  cwd working
  command 'sudo chef-client --local-mode webserver.rb --no-color --force-formatter --log_level warn'
end

f2_2_1 = stdout_file(cache, '2.2.1')
control_group '2.2' do
  control 'validate output' do
    describe file(f2_2_1) do
      [
        /^\s{2}\* yum_package\[httpd\] action install \(up to date\)$/,
        /^\s{2}\* service\[httpd\] action enable$/,
        /^\s{4}\- enable service service\[httpd\]$/,
        /^\s{2}\* service\[httpd\] action start$/,
        /^\s{4}\- start service service\[httpd\]$/
      ].each do |matcher|
        its(:content) { should match matcher }
      end
    end
  end
end

#---
# 3. Add a home page
#---

# Write webserver.rb.
file File.join(working, 'webserver.rb') do
  content <<-EOF.strip_heredoc
    package 'httpd'

    service 'httpd' do
      action [:enable, :start]
    end

    file '/var/www/html/index.html' do
      content '<html>
      <body>
        <h1>hello world</h1>
      </body>
    </html>'
    end
  EOF
end

# Run chef-client.
workflow_task '2.3.1' do
  cwd working
  command 'sudo chef-client --local-mode webserver.rb --no-color --force-formatter --log_level warn'
end

f2_3_1 = stdout_file(cache, '2.3.1')
control_group '2.3' do
  control 'validate output' do
    describe file(f2_3_1) do
      its(:content) { should match /^\s{4}\- create new file \/var\/www\/html\/index\.html$/ }
      its(:content) { should match /^\s{4}\- update content in file .+ from none/ }
      its(:content) { should match /^\s{4}\+\<html\>/ }
    end
  end
end

#---
# 4. Confirm your web site is running
#---

# Run chef-client.
workflow_task '2.4.1' do
  cwd working
  command 'curl localhost'
end

f2_4_1 = stdout_file(cache, '2.4.1')
control_group '2.4' do
  control 'validate output' do
    describe file(f2_4_1) do
      its(:content) { should match <<-EOF.strip_heredoc.chomp
        <html>
          <body>
            <h1>hello world</h1>
          </body>
        </html>
      EOF
      }
    end
  end
end
