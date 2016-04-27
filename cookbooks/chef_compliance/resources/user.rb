include LearnChef::Compliance

property :full_name, String, required: true
property :login, String, name_property: true
property :org_admin, TrueClass||FalseClass, required: false, default: true
property :site_admin, TrueClass||FalseClass, required: false, default: true
property :user_admin, TrueClass||FalseClass, required: false, default: true
property :password, String, required: false, default: "abc123!"

property :endpoint, String, required: false, default: 'https://chef-compliance.local/api'
property :port, Integer, required: false, default: 443
property :ssl_insecure, TrueClass||FalseClass, required: false, default: true

def api
  @api ||= ComplianceAPI.new(server: endpoint, port: port, ssl_insecure: ssl_insecure)
end

load_current_value do
  response = api.get("/users/#{login}")
  if response.nil?
    current_value_does_not_exist!
  end

  full_name response["name"]
  login response["login"]
  org_admin response["permissions"]["org_admin"].to_bool if response["permissions"]["org_admin"]
  site_admin response["permissions"]["site_admin"].to_bool if response["permissions"]["site_admin"]
  user_admin response["permissions"]["user_admin"].to_bool if response["permissions"]["user_admin"]
end

action :create do
  converge_if_changed do
    chef_gem 'httparty' do
      compile_time false
    end
    data = { "login" => login, "name" => full_name , "password" => password, "permissions" => {
      org_admin: org_admin.to_s,
      site_admin: site_admin.to_s,
      user_admin: user_admin.to_s
    }}
    if current_value
      api.patch("/users/#{login}", data)
    else
      api.post("/users", data)
    end
  end
end
