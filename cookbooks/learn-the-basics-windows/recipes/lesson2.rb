#
# Cookbook Name:: learn-the-basics-windows
# Recipe:: lesson2
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
#---
# Configure a package and service
#---

working = 'C:/Users/Administrator/chef-repo'
cache = 'C:/Users/Administrator/.acceptance/configure-a-package-and-service'

workflow_task_options 'Configure a package and service' do
  shell :powershell
  cache cache
end

directory working do
  action [:delete, :create]
  recursive true
end

#---
# 1. Install IIS
#---

# Write webserver.rb.
file File.join(working, 'webserver.rb') do
  content <<-EOF.strip_heredoc
    powershell_script 'Install IIS' do
      code 'Add-WindowsFeature Web-Server'
      guard_interpreter :powershell_script
      not_if "(Get-WindowsFeature -Name Web-Server).Installed"
    end
  EOF
end

# Run chef-client.
workflow_task '2.1.1' do
  cwd working
  command 'chef-client --local-mode webserver.rb --no-color --force-formatter --log_level warn'
end

# Run chef-client again.
workflow_task '2.1.2' do
  cwd working
  command 'chef-client --local-mode webserver.rb --no-color --force-formatter --log_level warn'
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
        /\* powershell_script\[Install IIS\] action run/,
        /Chef Client finished, 1/
      ].each do |matcher|
        its(:content) { should match matcher }
      end
    end
    describe file(f2_1_2) do
      its(:content) { should match /powershell_script\[Install IIS\] action run \(skipped due to not_if\)/ }
    end
  end
end

#---
# 2. Start the World Wide Web Publishing Service
#---

# Write webserver.rb.
file File.join(working, 'webserver.rb') do
  content <<-EOF.strip_heredoc
    powershell_script 'Install IIS' do
      code 'Add-WindowsFeature Web-Server'
      guard_interpreter :powershell_script
      not_if "(Get-WindowsFeature -Name Web-Server).Installed"
    end

    service 'w3svc' do
      action [:enable, :start]
    end
  EOF
end

# Run chef-client.
workflow_task '2.2.1' do
  cwd working
  command 'chef-client --local-mode webserver.rb --no-color --force-formatter --log_level warn'
end

f2_2_1 = stdout_file(cache, '2.2.1')
control_group '2.2' do
  control 'validate output' do
    describe file(f2_2_1) do
      [
        /^\s{2}\* powershell_script\[Install IIS\] action run \(skipped due to not_if\)$/,
        /^\s{2}\* windows_service\[w3svc\] action enable \(up to date\)$/,
        /^\s{2}\* windows_service\[w3svc\] action start \(up to date\)$/
      ].each do |matcher|
        its(:content) { should match matcher }
      end
    end
  end
end

#---
# 3. Configure the home page
#---

# Write webserver.rb.
file File.join(working, 'webserver.rb') do
  content <<-'EOF'.strip_heredoc
    powershell_script 'Install IIS' do
      code 'Add-WindowsFeature Web-Server'
      guard_interpreter :powershell_script
      not_if "(Get-WindowsFeature -Name Web-Server).Installed"
    end

    service 'w3svc' do
      action [:enable, :start]
    end

    file 'c:\inetpub\wwwroot\Default.htm' do
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
  command 'chef-client --local-mode webserver.rb --no-color --force-formatter --log_level warn'
end

f2_3_1 = stdout_file(cache, '2.3.1')
control_group '2.3' do
  control 'validate output' do
    describe file(f2_3_1) do
      its(:content) { should match /^\s{2}\* file\[c:\\inetpub\\wwwroot\\Default\.htm\] action create$/ }
      its(:content) { should match /^\s{4}\- update content in file/ }
      its(:content) { should match /^\s{4}\+\<html\>/ }
    end
  end
end

#---
# 4. Confirm your web site is running
#---

# Note: The tutorial has you run `(Invoke-WebRequest localhost).Content`, but this will
# error if the IE first-launch configuration is not complete. This work-around should be fine,
# as we're not testing iwr.
workflow_task '2.4.1' do
  cwd working
  command "(New-Object Net.WebClient).DownloadString('http://localhost')"
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
