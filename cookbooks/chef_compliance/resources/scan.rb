include LearnChef::Compliance

property :profile_owner, String, default: lazy { name.split(/\//)[0] }
property :profile_name, String, default: lazy { name.split(/\//)[1] }
property :environment, String
property :node_name, String
property :patchlevel, String, default: 'default'

property :endpoint, String, required: false, default: 'https://chef-compliance.local/api', identity: false
property :port, Integer, required: false, default: 443, identity: false
property :ssl_insecure, TrueClass||FalseClass, required: false, default: true, identity: false

def api
  @api ||= ComplianceAPI.new(server: endpoint, port: port, ssl_insecure: ssl_insecure)
end

# def f_profile_owner
#   api.get("/user/compliance").each_value do |v|
#     v.each_value do |v2|
#       puts v2 if v2['name'] == profile_name
#       return v2['owner'] if v2['name'] == profile_name
#     end
#   end
# end

def environment_owner
  environment.split(/\//)[0]
end

def environment_name
  environment.split(/\//)[1]
end

def environment_id
  api.get("/owners/#{environment_owner}/envs/#{environment_name}")['id']
end

def node_id
  puts "!!!!/owners/#{environment_owner}/envs/#{environment_name}/nodes"
  api.get("/owners/#{environment_owner}/envs/#{environment_name}/nodes").find {|h| h['name'] == node_name}['id']
end

load_current_value do
  current_value_does_not_exist!
end

action :run do
  converge_if_changed do
    data = {
      "compliance" => [{
        "owner" => profile_owner,
        "profile" => profile_name
      }],
      "environments" => [{
        "id" => environment_id,
        "nodes" => [node_id]
      }],
      "patchlevel" => [{
        "profile" => patchlevel
      }]
    }
    puts data.to_json
    puts "/api/owners/#{environment_owner}/scans"
    response = api.post("/api/owners/#{environment_owner}/scans", data)
    puts response
  end
end
