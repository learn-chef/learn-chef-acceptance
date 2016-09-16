#
# Cookbook Name:: learn-the-basics-windows
# Recipe:: lesson1
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
#---
# Configure a resource
#---

working = 'C:/Users/Administrator/chef-repo'
cache = 'C:/Users/Administrator/.acceptance/configure-a-resource'

workflow_task_options 'Configure a resource' do
  shell :powershell
  cache cache
end

#---
# 1. Ensure you have Administrator privileges
#---

# no tests

#---
# 2. Set up your working directory
#---

directory working do
  action [:delete, :create]
  recursive true
end

#---
# 3. Create the INI file
#---

file File.join(working, 'hello.rb') do
  content <<-'EOF'.strip_heredoc
    file 'C:\Users\Administrator\chef-repo\settings.ini' do
      content 'greeting=hello world'
    end
  EOF
end

workflow_task '1.3.1' do
  cwd working
  command 'chef-client --local-mode hello.rb --no-color --force-formatter'
end

workflow_task '1.3.2' do
  cwd working
  command 'Get-Content settings.ini'
end

workflow_task '1.3.3' do
  cwd working
  command 'chef-client --local-mode hello.rb --no-color --force-formatter'
end

step3_matchers = [
  /WARN: No config file found or specified on command line, using command line options\./,
  /WARN: No cookbooks directory found at or above current directory\./,
  /Starting Chef Client, version /,
  /resolving cookbooks for run list: \[\]/,
  /Synchronizing Cookbooks:/,
  /Compiling Cookbooks/,
  /WARN: Node .+ has an empty run list/,
  /Converging 1 resources/,
  /Recipe: @recipe_files::C:\/Users\/Administrator\/chef\-repo\/hello\.rb/,
  /\s{2}* file\[C:\\Users\\Administrator\\chef-repo\\settings.ini\] action create/,
  /\s{4}\- create new file C:\\Users\\Administrator\\chef-repo\\settings.ini/,
  /\s{4}\- update content in file C:\\Users\\Administrator\\chef-repo\\settings.ini from none to .+/,
  /\s{4}\-\-\- C:\\Users\\Administrator\\chef-repo\\settings.ini/,
  /\s{4}\+\+\+ C:\\Users\\Administrator\\chef-repo\/chef-settings/,
  /\s{4}\+greeting=hello world/,
  /Running handlers:/,
  /Running handlers complete/,
  /Chef Client finished, 1\/1 resources updated in \d\d seconds/
]

f1_3_1 = stdout_file(cache, '1.3.1')
f1_3_2 = stdout_file(cache, '1.3.2')
f1_3_3 = stdout_file(cache, '1.3.3')
control_group '1.3' do
  control 'validate output' do
    describe file(f1_3_1) do
      step3_matchers.each do |matcher|
        its(:content) { should match matcher }
      end
    end
  end
  control 'validate result' do
    describe file(f1_3_2) do
      its(:content) { should match /^greeting=hello world$/ }
    end
  end
  control 'validate output' do
    describe file(f1_3_3) do
      its(:content) { should match /\* file\[C:\\Users\\Administrator\\chef-repo\\settings.ini\] action create \(up to date\)$/ }
      its(:content) { should match /Chef Client finished, 0\/1 resources updated in \d\d seconds$/ }
    end
  end
end

#---
# 4. Update the INI file's contents
#---

file File.join(working, 'hello.rb') do
  content <<-'EOF'.strip_heredoc
    file 'C:\Users\Administrator\chef-repo\settings.ini' do
      content 'greeting=hello chef'
    end
  EOF
end

workflow_task '1.4.1' do
  cwd working
  command 'chef-client --local-mode hello.rb --no-color --force-formatter'
end

workflow_task '1.4.2' do
  cwd working
  command 'Get-Content settings.ini'
end

f1_4_1 = stdout_file(cache, '1.4.1')
f1_4_2 = stdout_file(cache, '1.4.2')
control_group '1.4' do
  control 'validate output' do
    describe file(f1_4_1) do
      its(:content) { should match /\-greeting=hello world/ }
      its(:content) { should match /\+greeting=hello chef/ }
    end
  end
  control 'validate result' do
    describe file(f1_4_2) do
      its(:content) { should match /^greeting=hello chef$/ }
    end
  end
end

#---
# 5. Ensure the INI file's contents are not changed by anyone else
#---

powershell_script "Set-Content settings.ini 'greeting=hello robots'" do
  code "Set-Content settings.ini 'greeting=hello robots'"
  cwd working
end

workflow_task '1.5.1' do
  cwd working
  command 'chef-client --local-mode hello.rb --no-color --force-formatter'
end

workflow_task '1.5.2' do
  cwd working
  command 'Get-Content settings.ini'
end

f1_5_1 = stdout_file(cache, '1.5.1')
f1_5_2 = stdout_file(cache, '1.5.2')
control_group '1.5' do
  control 'validate output' do
    describe file(f1_5_1) do
      its(:content) { should match /\-greeting=hello robots/ }
      its(:content) { should match /\+greeting=hello chef/ }
    end
  end
  control 'validate result' do
    describe file(f1_5_2) do
      its(:content) { should match /^greeting=hello chef$/ }
    end
  end
end

#---
# 6. Delete the INI file
#---

file File.join(working, 'goodbye.rb') do
  content <<-'EOF'.strip_heredoc
    file 'C:\Users\Administrator\chef-repo\settings.ini' do
      action :delete
    end
  EOF
end

workflow_task '1.6.1' do
  cwd working
  command 'chef-client --local-mode goodbye.rb --no-color --force-formatter'
end

workflow_task '1.6.2' do
  cwd working
  command 'Test-Path settings.ini'
end

f1_6_1 = stdout_file(cache, '1.6.1')
f1_6_2 = stdout_file(cache, '1.6.2')
control_group '1.6' do
  control 'validate output' do
    describe file(f1_6_1) do
      its(:content) { should match /\s{2}\* file\[C:\\Users\\Administrator\\chef-repo\\settings.ini\] action delete/ }
      its(:content) { should match /\s{4}\- delete file C:\\Users\\Administrator\\chef-repo\\settings.ini/ }
    end
  end
  control 'validate result' do
    describe file(f1_6_2) do
      its(:content) { should match /False$/ }
    end
  end
end
