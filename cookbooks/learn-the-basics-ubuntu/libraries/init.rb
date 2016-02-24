Chef::Recipe.send(:include, LearnChef::Workflow)

require 'rspec'
RSpec.configure do |c|
  c.include LearnChef::Workflow
end
