#
# Cookbook Name:: learn-the-basics-rhel
# Recipe:: lesson1
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
#---
# Configure a resource
#---

working = File.join(ENV['HOME'], 'chef-repo')
cache = File.join(ENV['HOME'], '.acceptance/configure-a-resource')

workflow_task_options 'Configure a resource' do
  shell :bash
  cache cache
end

#---
# 1.1. Set up your working directory
#---

directory working do
  action [:delete, :create]
  recursive true
end

#---
# 2. Create the MOTD file
#---

file File.join(working, 'hello.rb') do
  content <<-EOF.strip_heredoc
    file '/tmp/motd' do
      content 'hello world'
    end
  EOF
end

workflow_task '1.2.1' do
  cwd working
  command 'chef-client --local-mode hello.rb --no-color --force-formatter --log_level warn'
end

workflow_task '1.2.2' do
  cwd working
  command 'more /tmp/motd'
end

workflow_task '1.2.3' do
  cwd working
  command 'chef-client --local-mode hello.rb --no-color --force-formatter --log_level warn'
end

step2_matchers = [
  /WARN: No config file found or specified on command line, using command line options\./,
  /WARN: No cookbooks directory found at or above current directory\./,
  /Starting Chef Client, version /,
  /resolving cookbooks for run list: \[\]/,
  /Synchronizing Cookbooks:/,
  /Compiling Cookbooks/,
  /WARN: Node .+ has an empty run list/,
  /Converging 1 resources/,
  /Recipe: @recipe_files::\/.+\/chef\-repo\/hello.rb/,
  /\s{2}* file\[\/tmp\/motd\] action create/,
  /\s{4}\- create new file \/tmp\/motd/,
  /\s{4}\- update content in file \/tmp\/motd from none to .+/,
  /\s{4}\-\-\- \/tmp\/motd/,
  /\s{4}\+\+\+ \/tmp\/\.(chef-)?motd/,
  /\s{4}\+hello world/,
  /\s{4}\- restore selinux security context/,
  /Running handlers:/,
  /Running handlers complete/,
  /Chef Client finished, 1\/1 resources updated in \d\d seconds/
]

f1_2_1 = stdout_file(cache, '1.2.1')
f1_2_2 = stdout_file(cache, '1.2.2')
f1_2_3 = stdout_file(cache, '1.2.3')
control_group '1.2.1' do
  control 'validate output' do
    describe file(f1_2_1) do
      step2_matchers.each do |matcher|
        its(:content) { should match matcher }
      end
    end
  end
  control 'validate result' do
    describe file(f1_2_2) do
      its(:content) { should match /^hello world$/ }
    end
  end
  control 'validate output' do
    describe file(f1_2_3) do
      its(:content) { should match /\* file\[\/tmp\/motd\] action create \(up to date\)$/ }
      its(:content) { should match /Chef Client finished, 0\/1 resources updated in \d\d seconds$/ }
    end
  end
end

#---
# 3. Update the MOTD file's contents
#---

file File.join(working, 'hello.rb') do
  content <<-EOF.strip_heredoc
    file '/tmp/motd' do
      content 'hello chef'
    end
  EOF
end

workflow_task '1.3.1' do
  cwd working
  command 'chef-client --local-mode hello.rb --no-color --force-formatter --log_level warn'
end

workflow_task '1.3.2' do
  cwd working
  command 'more /tmp/motd'
end

f1_3_1 = stdout_file(cache, '1.3.1')
f1_3_2 = stdout_file(cache, '1.3.2')
control_group '1.1.3' do
  control 'validate output' do
    describe file(f1_3_1) do
      its(:content) { should match /\-hello world/ }
      its(:content) { should match /\+hello chef/ }
    end
  end
  control 'validate result' do
    describe file(f1_3_2) do
      its(:content) { should match /^hello chef$/ }
    end
  end
end

#---
# 4. Ensure the MOTD file's contents are not changed by anyone else
#---

execute "echo 'hello robots' > /tmp/motd" do
  cwd working
end

workflow_task '1.4.1' do
  cwd working
  command 'chef-client --local-mode hello.rb --no-color --force-formatter --log_level warn'
end

workflow_task '1.4.2' do
  cwd working
  command 'more /tmp/motd'
end

f1_4_1 = stdout_file(cache, '1.4.1')
f1_4_2 = stdout_file(cache, '1.4.2')
control_group '1.1.4' do
  control 'validate output' do
    describe file(f1_4_1) do
      its(:content) { should match /\-hello robots/ }
      its(:content) { should match /\+hello chef/ }
    end
  end
  control 'validate result' do
    describe file(f1_4_2) do
      its(:content) { should match /^hello chef$/ }
    end
  end
end

#---
# 5. Delete the MOTD file
#---

file File.join(working, 'goodbye.rb') do
  content <<-EOF.strip_heredoc
    file '/tmp/motd' do
      action :delete
    end
  EOF
end

workflow_task '1.5.1' do
  cwd working
  command 'chef-client --local-mode goodbye.rb --no-color --force-formatter --log_level warn'
end

workflow_task '1.5.2' do
  cwd working
  command 'more /tmp/motd'
end

f1_5_1 = stdout_file(cache, '1.5.1')
f1_5_2 = stderr_file(cache, '1.5.2')
control_group '1.1.5' do
  control 'validate output' do
    describe file(f1_5_1) do
      its(:content) { should match /\s{2}\* file\[\/tmp\/motd\] action delete/ }
      its(:content) { should match /\s{4}\- delete file \/tmp\/motd/ }
    end
  end
  control 'validate result' do
    describe file(f1_5_2) do
      its(:content) { should match /\/tmp\/motd: No such file or directory$/ }
    end
  end
end
