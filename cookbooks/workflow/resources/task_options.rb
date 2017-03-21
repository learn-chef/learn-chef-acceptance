include LearnChef::Workflow

# directory to write output to.
property :cache, [String, nil], required: false, default: nil
# the shell to run the command from. options are :bash and :powershell.
property :shell, Symbol, required: false, default: :bash
# a Hash of environment variables to set before the command is run.
property :environment, Hash, required: false, default: {}

action :set do
  changed_settings = {}
  changed_settings[:cache] = {}
  changed_settings[:shell] = {}
  changed_settings[:environment] = {}

  task_options.each do |key, value|
    changed_settings[key][:old] = value
  end
  changed_settings[:cache][:new] = cache
  changed_settings[:shell][:new] = shell
  changed_settings[:environment][:new] = environment

  changed_settings.keys.sort.each do |key|
    Chef::Log.info("  * #{key}: #{changed_settings[key][:old]} => #{changed_settings[key][:new]}")
  end

  assign_task_options(
    cache: cache,
    shell: shell,
    environment: environment
    )
end
