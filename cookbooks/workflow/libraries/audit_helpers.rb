module LearnChef module Workflow
  class Audit
    @@node = nil
    def self.node=(node)
      @@node = node
    end
    def self.node
      @@node
    end
  end

  def validate_sample_output?
    !Audit::node['chef_acceptance']
  end
  def validate_tool_versions?
    !Audit::node['chef_acceptance']
  end
end; end
