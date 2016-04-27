include LearnChef::Compliance

property :owner, String, identity: true, default: lazy { name.split(/\//)[0] }
property :env_name, String, identity: true, default: lazy { name.split(/\//)[1] }
property :node_name, String, identity: true, default: lazy { name.split(/\//)[2] }

property :hostname, String
property :login_user, String, default: "root"
property :login_method, String, default: "sshPassword"
property :login_key, String
property :login_password, String
property :login_port, Integer, default: 22

property :endpoint, String, required: false, default: 'https://chef-compliance.local/api', identity: false
property :port, Integer, required: false, default: 443, identity: false
property :ssl_insecure, TrueClass||FalseClass, required: false, default: true, identity: false

def api
  @api ||= ComplianceAPI.new(server: endpoint, port: port, ssl_insecure: ssl_insecure)
end

attr_accessor :id

load_current_value do
  response = api.get("/owners/#{owner}/envs/#{env_name}/nodes")
  if response.nil? || response == "404 page not found"
    current_value_does_not_exist!
  end

  node = response.find {|h| h['name'] == node_name}
  current_value_does_not_exist! if node.nil?

  hostname node['hostname']
  login_user node['loginUser']
  login_method node['loginMethod']
  login_key node['loginKey']
  login_port node['loginPort']
  @id = node['id']
end

action :create do
  converge_if_changed do
    data = { "name" => node_name, "hostname" => hostname, "loginUser" => login_user, "loginMethod" => login_method, "loginKey" => login_key, "loginPort" => login_port }
    data["loginPassword"] = login_password if login_password
    if current_value
      response = api.patch("/owners/#{owner}/envs/#{env_name}/nodes/#{current_value.id}", data)
    else
      response = api.post("/owners/#{owner}/envs/#{env_name}/nodes", data)
    end
  end
end
