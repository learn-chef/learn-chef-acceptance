include LearnChef::Compliance

property :owner, String, identity: true, default: lazy { name.split(/\//)[0] }
property :env_name, String, identity: true, default: lazy { name.split(/\//)[1] }

property :endpoint, String, required: false, default: 'https://chef-compliance.local/api', identity: false
property :port, Integer, required: false, default: 443, identity: false
property :ssl_insecure, TrueClass||FalseClass, required: false, default: true, identity: false

def api
  @api ||= ComplianceAPI.new(server: endpoint, port: port, ssl_insecure: ssl_insecure)
end

load_current_value do
  response = api.get("/owners/#{owner}/envs/#{env_name}")
  if response.nil? || response == "404 page not found"
    current_value_does_not_exist!
  end

  env_name response['name']
  owner response['owner']
end

action :create do
  converge_if_changed do
    if current_value
      #raise "Modifying an environment is not supported. Current owner is #{current_value['owner']}".
    else
      data = { "name" => env_name }
      response = api.post("/owners/#{owner}/envs", data)
      puts "!!!"
      puts response
      puts "!!!"
    end
  end
end
