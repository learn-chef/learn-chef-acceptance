#
# Cookbook Name:: learn-the-basics-windows
# Recipe:: lesson3
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
#---
# Make your recipe more manageable
#---

repo = 'C:/Users/Administrator/chef-repo'
cookbooks = 'C:/Users/Administrator/chef-repo/cookbooks'
cache = 'C:/Users/Administrator/.acceptance/make-your-recipe-more-manageable'

workflow_task_options 'Make your recipe more manageable' do
  shell :powershell
  cache cache
end

[repo, cookbooks].each do |dir|
  directory dir do
    action [:create]
    recursive true
  end
end

#---
# 1. Create a cookbook
#---

# Create cookbook.
workflow_task '3.1.1' do
  cwd cookbooks
  command 'chef generate cookbook learn_chef_iis'
end

# Run tree.
workflow_task '3.1.2' do
  cwd cookbooks
  command 'tree /F'
end

f3_1_2 = stdout_file(cache, '3.1.2')
control_group '3.1' do
  control 'validate output' do
    describe file(f3_1_2) do
      # TODO: Why isn't `have` available?
      # its(:content) { should have(29).lines }
    end
  end
end

#---
# 2. Create a template
#---

# Create template.
workflow_task '3.2.1' do
  cwd cookbooks
  command 'chef generate template learn_chef_iis Default.htm'
end

# Run tree.
workflow_task '3.2.2' do
  cwd cookbooks
  command 'tree /F'
end

f3_2_2 = stdout_file(cache, '3.2.2')
control_group '3.2' do
  control 'validate output' do
    describe file(f3_2_2) do
      # TODO: Why isn't `have` available?
      # its(:content) { should have(33).lines }
    end
  end
end

file File.join(cookbooks, 'learn_chef_iis/templates/default/Default.htm.erb') do
  content <<-EOF.strip_heredoc
    <html>
      <body>
        <h1>hello world</h1>
      </body>
    </html>
  EOF
end

#---
# 3. Update the recipe to reference the HTML template
#---

# Update recipe.
file File.join(cookbooks, 'learn_chef_iis/recipes/default.rb') do
  content <<-'EOF'.strip_heredoc
    powershell_script 'Install IIS' do
      code 'Add-WindowsFeature Web-Server'
      guard_interpreter :powershell_script
      not_if "(Get-WindowsFeature -Name Web-Server).Installed"
    end

    service 'w3svc' do
      action [:enable, :start]
    end

    template 'c:\inetpub\wwwroot\Default.htm' do
      source 'Default.htm.erb'
    end
  EOF
end

#---
# 4. Run the cookbook
#---

# Run chef-client.
workflow_task '3.4.1' do
  cwd repo
  command "chef-client --local-mode --runlist 'recipe[learn_chef_iis]' --no-color --force-formatter --log_level warn"
end

f3_4_1 = stdout_file(cache, '3.4.1')
control_group '3.4' do
  control 'validate output' do
    describe file(f3_4_1) do
      its(:content) { should match /Starting Chef Client, version 12\.7/ }
      its(:content) { should match /Chef Client finished, 1\/4 resources updated in \d+ seconds/ }
    end
  end
end
