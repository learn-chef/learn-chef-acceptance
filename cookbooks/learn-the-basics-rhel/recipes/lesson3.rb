#
# Cookbook Name:: learn-the-basics-rhel
# Recipe:: lesson3
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
#---
# Make your recipe more manageable
#---

repo = File.join(ENV['HOME'], 'chef-repo')
cookbooks = File.join(repo, 'cookbooks')
cache = File.join(ENV['HOME'], '.acceptance/make-your-recipe-more-manageable')

workflow_task_options 'Make your recipe more manageable' do
  shell :bash
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
  command 'chef generate cookbook learn_chef_httpd'
end

# Run tree.
workflow_task '3.1.2' do
  cwd cookbooks
  command 'tree'
end

f3_1_2 = stdout_file(cache, '3.1.2')
control_group '3.1' do
  control 'validate output' do
    describe file(f3_1_2) do
      its(:content) { should match /11 directories, 9 files/ }
    end
  end
end

#---
# 2. Create a template
#---

# Create template.
workflow_task '3.2.1' do
  cwd cookbooks
  command 'chef generate template learn_chef_httpd index.html'
end

# Run tree.
workflow_task '3.2.2' do
  cwd cookbooks
  command 'tree'
end

f3_2_2 = stdout_file(cache, '3.2.2')
control_group '3.2' do
  control 'validate output' do
    describe file(f3_2_2) do
        its(:content) { should match /13 directories, 10 files/ }
    end
  end
end

file File.join(cookbooks, 'learn_chef_httpd/templates/default/index.html.erb') do
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
file File.join(cookbooks, 'learn_chef_httpd/recipes/default.rb') do
  content <<-EOF.strip_heredoc
    package 'httpd'

    service 'httpd' do
      action [:enable, :start]
    end

    template '/var/www/html/index.html' do
      source 'index.html.erb'
    end
  EOF
end

#---
# 4. Run the cookbook
#---

# Run chef-client.
workflow_task '3.4.1' do
  cwd repo
  command "sudo chef-client --local-mode --runlist 'recipe[learn_chef_httpd]' --no-color --force-formatter --log_level warn"
end

f3_4_1 = stdout_file(cache, '3.4.1')
control_group '3.4' do
  control 'validate output' do
    describe file(f3_4_1) do
      its(:content) { should match /Starting Chef Client, version/ }
      its(:content) { should match /Chef Client finished, 1\/4 resources updated in \d+ seconds/ }
    end
  end
end
