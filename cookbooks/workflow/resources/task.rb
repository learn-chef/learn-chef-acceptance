include LearnChef::Workflow
include Chef::Mixin::ShellOut

# this is used to name the subdirectory where the output (stdout, stderr, exit code) is written.
property :name, String, name_property: true
# the command to run.
property :command, String, required: true
# the directory to run the command.
property :cwd, String, required: true
# directory to write output to.
property :cache, [String, nil], required: false, default: nil
# the shell to run the command from. options are :bash and :powershell.
property :shell, Symbol, required: false, default: :current
# a Hash of environment variables to set before the command is run.
property :environment, Hash, required: false, default: {}

action :run do
  # Ensure working directory exists.
  directory cwd do
    recursive true
  end

  # Override anything mentioned in with_task_options.
  resolved_shell = (shell == :current) ? task_options[:shell] : shell
  resolved_environment = (environment.empty?) ? task_options[:environment] : environment
  resolved_cache = (cache.nil?) ? task_options[:cache] : cache

  # Generate final command to run.
  case resolved_shell
  when :bash
    cmd = command
  when :powershell
    cmd = "powershell.exe -Command \"#{command}\""
  end

  # Run the command.
  result = shell_out(cmd, cwd: cwd, environment: resolved_environment)

  # Write the result to disk.
  unless resolved_cache.nil?
    # Ensure cache directory exists.
    directory ::File.join(resolved_cache, name) do
      recursive true
    end

    # Write stdout.
    file stdout_file(resolved_cache, name) do
      content result.stdout
    end
    # Write stderr.
    file stderr_file(resolved_cache, name) do
      content result.stderr
    end
    # Write exit code.
    file status_file(resolved_cache, name) do
      content result.exitstatus.to_s
    end
    # Write the command (helps with debugging).
    file command_file(resolved_cache, name) do
      content command
    end
  end
end
