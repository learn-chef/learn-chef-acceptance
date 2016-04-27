require 'net/http'
require 'uri'
require 'resolv-replace.rb'

module LearnChef module Compliance

  # def api_version(uri, username, password)
  #   require 'rest-client'
  #   p Resolv.getaddress "chef-compliance.local"
  #
  #   http = Net::HTTP.new("https://chef-compliance.local")
  #   http.use_ssl = false
  #   http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  #   request = Net::HTTP::Get.new("/api/version")
  #   response = http.request(request)
  #   puts response
  # end
  #
  # def api_token(uri, username, password)
  #   http = Net::HTTP.new("https://192.168.77.77/api")
  #   http.use_ssl = true
  #   http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  #   request = Net::HTTP::Post.new("/oauth/token")
  #   request.set_form_data({"u" => "#{username}:#{password}", "d" => "grant_type=client_credentials"})
  #   response = http.request(request)
  #   puts response
  # end

# https://www.drewstud.com/chef/ruby/rest/httparty/raw/api/2016/01/19/query-chef-rest-api.html

  require 'base64'
require 'time'
require 'digest/sha1'
require 'openssl'
require 'net/https'
require 'json'
require 'pry'

class ComplianceAPI
  # Public: Gets/Sets the String path for the HTTP request.
  attr_accessor :path

  # Public: Gets/Sets the String client_name containing the Chef client name.
  #attr_accessor :client_name

  # Public: Gets/Sets the String key_file that is path to the Chef client PEM file.
  #attr_accessor :key_file
  #attr_accessor :password

  # Public: Initialize a Chef API call.
  #
  # opts - A Hash containing the settings desired for the HTTP session and auth.
  #        :server       - The String server that is the Chef server name (required).
  #        :port         - The String port for the Chef server (default: 443).
  #        :use_ssl      - The Boolean use_ssl to use Net::HTTP SSL
  #                        functionality or not (default: true).
  #        :ssl_insecure - The Boolean ssl_insecure to skip strict SSL cert
  #                        checking (default: OpenSSL::SSL::VERIFY_PEER).
  #        :client_name  - The String client_name that is the name of the Chef
  #                        client (required).
  #        :key_file     - The String key_file that is the path to the Chef client
  #                        PEM file (required).
  def initialize(opts = {})
    @server            = opts[:server]
    @port              = opts.fetch(:port, 443)
    @verify_mode       = opts[:ssl_insecure] ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER

    require 'httparty'
    HTTParty::Basement.default_options.update(verify: !opts.fetch(:ssl_insecure, false))

    #@client_name      = opts[:client_name]
    #@key_file         = opts[:key_file]
  #  @password = opts[:password]
    #@@api_key = post_request('/oauth/token', '', query: {grant_type: 'client_credentials'}, basic_auth: {username: 'admin', password: 'admin'})["access_token"]
    @@api_key = "eyJhbGciOiJSUzI1NiIsImtpZCI6InJRZEtpQlNPM2RaVVJJU09aUGpXOTZnbHBVOV83cUlWcVh1SWl2U1Fxd1JibDRsaURWdHhIeGRfQkpYTUNiRkZnNE1KRzJrdi1mamEwcmREcnN0Yk9vT25QMVhPRTJhckJsNk1VNHpNLVhZQm5EaFkwRDRqMXFEWmUxdmxTSnd2UzI5TmxjUG43TXM3Q090bm5qTmFPRDJsVmlOTUNJTXRkUENURlRnbDdZX3JOMFBCRG4zNlRQRlRwcjluWjdmZnRBNjZiX29zMzdHd0pGOThEV25kWjk5RjdFTG9VLXY2cjI4dE1uREUtQTJzRHVLU05kYndjdEVkaFA0WG5Fd2JnUkZpT2VUMTRyVUdnZzVrZ2tVRi1Fb0x5S0pBdXJPZHJMNmJGM0NQMnZFM1h6NTNGX18xeXkxQTNwYjNGc3VFbXFESFlfQ2x4VG5qRVRKODB3SXU4UT09IiwidHlwIjoiSldUIn0.eyJhdWQiOiJhQ2p5d2xYRWU4RzNsclotWVdsYU8xVFVxTEZfcm1jQzA4UVI0MTdzdDdvPUBjaGVmLWNvbXBsaWFuY2UubG9jYWwiLCJjb25uZWN0b3JfaWQiOiJDb21wbGlhbmNlIFNlcnZlciIsImNvbm5lY3Rvcl9pbmZvIjoiaHR0cHM6Ly9jaGVmLWNvbXBsaWFuY2UubG9jYWwvYXBpLyIsImNvbm5lY3Rvcl90eXBlIjoiY29tcGxpYW5jZSIsImVtYWlsIjoiYWRtaW5AY29tcGxpYW5jZS5mYWtlIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImV4cCI6MS40NjA1NjM1MzRlKzA5LCJpYXQiOjEuNDYwNTIwMzM0ZSswOSwiaXNzIjoiaHR0cHM6Ly9jaGVmLWNvbXBsaWFuY2UubG9jYWwiLCJuYW1lIjoiYWRtaW4iLCJzdWIiOiJjMDdmZGEwMi05MjhmLTRjYWYtYjkxYi1iM2U5ZTZhM2RkYWEifQ.iwKNit1QKSwJ-CuUVLSFCGpNyuK3mUE1Tq2Q1EJE2x4XD_Qimvc0ioy5nc2SvXeBZRGamLsHAVbmjGQf6Yzx53-4AIIaKfz0jMQn7JecemSBzrrIMBCPApsBbZfZDgYrQA2Dk8IPPSXm7Uip1XM2vYjtLw9vD28qaiBKcobYIboVTUld_oaerrSkB2G3UfTrWGDrEC1XeBqFAZaHyj5farJq7I-Hnz26BukVLxkda-cXkWUegNxBwxYmnWROLXc7JERYodp5hBOqBSJ9t9uZ8rftD9kBdWN-Rt2EDqN5dOg_ym83JDIVTHQu6xvP8RVI29Ud-R23g_2zSdcOFSWpwQ"
    #puts @@api_key
    #puts "ADD USER"
    #user = post_request2('/users', name: "Lee Doe2", login: "lee3", password: "l8dDnwr0fgh", permissions: {"org_admin"=>"true","site_admin"=>"true","user_admin"=>"true"})
    #puts user
    #puts "!!ADD USER"
    #users = get_request('/users')
    #puts users
    #puts "^^ users"
  end

  # Public: Make the actual GET request to the Chef server.
  #
  # req_path - A String containing the server path you want to send with your
  #            GET request (required).
  #
  # Examples
  #
  #   get_request('/environments/_default/nodes')
  #   # => ["server1.com","server2.com","server3.com"]
  #
  # Returns different Object type depending on request.
  def get(req_path, data = '')
    require 'httparty'
    @path = req_path
    reqpath = @server + req_path
    begin
      response = HTTParty.get(reqpath, headers: headers('', 'GET'), body: data.to_json)
      #puts response.inspect
      response.parsed_response
      # JSON.parse(response.body).keys
    rescue OpenSSL::SSL::SSLError => e
      raise "SSL error: #{e.message}."
    end
  end

  def put(req_path, body)
    require 'httparty'
    @path = req_path
    reqpath = @server + req_path
    #puts reqpath
    begin
      response = HTTParty.put(reqpath, headers: headers(body, 'PUT'), body: body.to_json)
      response.parsed_response
    rescue OpenSSL::SSL::SSLError => e
      raise "SSL error: #{e.message}."
    end
  end

  def patch(req_path, body)
    require 'httparty'
    @path = req_path
    reqpath = @server + req_path
    #puts reqpath
    begin
      response = HTTParty.patch(reqpath, headers: headers(body, 'PATCH'), body: body.to_json)
      response.parsed_response
    rescue OpenSSL::SSL::SSLError => e
      raise "SSL error: #{e.message}."
    end
  end

  def post(req_path, data)
    # http = Net::HTTP.new(@server, @port)
    # http.use_ssl = true
    # http.verify_mode = OpenSSL::SSL::VERIFY_NONE # TODO
    #
    # request = Net::HTTP::Post.new(req_path, headers('', 'POST'))
    # request.body = data.to_json
    #
    # http.request(request)
    ###
    require 'httparty'
    @path = req_path
    reqpath = @server + req_path
    #puts reqpath
    begin
      # options = {}
      # options[:body] = data.to_json
      # options[:headers] = headers('', 'POST')
      response = HTTParty.post(reqpath, headers: headers('', 'POST'), body: data.to_json)
      #puts response.inspect
      response.parsed_response
    rescue OpenSSL::SSL::SSLError => e
      raise "SSL error: #{e.message}."
    end
  end

  # def post_request(req_path, body, options={})
  #   require 'httparty'
  #   @path = req_path
  #   reqpath = @server + req_path
  #   puts reqpath
  #   begin
  #     puts headers(body, 'POST')
  #     options[:body] = body
  #     options[:headers] = {} if options[:headers].nil?
  #     options[:headers].merge!(headers(body, 'POST'))
  #     puts "!!!"
  #     puts options
  #     puts "!!!"
  #     response = HTTParty.post(reqpath, options)
  #     puts response.inspect
  #     response.parsed_response
  #   rescue OpenSSL::SSL::SSLError => e
  #     raise "SSL error: #{e.message}."
  #   end
  # end

  def delete(req_path, body)
    require 'httparty'
    @path = req_path
    reqpath = @server + req_path
    puts reqpath
    begin
      response = HTTParty.delete(reqpath, headers: headers(body, 'DELETE'), body: body)
      response.parsed_response
    rescue OpenSSL::SSL::SSLError => e
      raise "SSL error: #{e.message}."
    end
    end

  private

  # Private: Encode a String with SHA1.digest and then Base64.encode64 it.
  #
  # string - The String you want to encode.
  #
  # Examples
  #
  #   encode('hello')
  #   # => "qvTGHdzF6KLavt4PO0gs2a6pQ00="
  #
  # Returns the hashed String.
  def encode(string)
    ::Base64.encode64(Digest::SHA1.digest(string)).chomp
  end

  # Private: Forms the HTTP headers required to authenticate and query data
  # via Chef's REST API.
  #
  # Examples
  #
  #   headers
  #   # => {
  #     "Accept"                => "application/json",
  #     "X-Ops-Sign"            => "version=1.0",
  #     "X-Ops-Userid"          => "client-name",
  #     "X-Ops-Timestamp"       => "2012-07-27T20:09:25Z",
  #     "X-Ops-Content-Hash"    => "JJKXjxksmsKXM=",
  #     "X-Ops-Authorization-1" => "JFKXjkmdkDMKCMDKd+",
  #     "X-Ops-Authorization-2" => "JFJXjxjJXXJ/FFjxjd",
  #     "X-Ops-Authorization-3" => "FFJfXffffhhJjxFJff",
  #     "X-Ops-Authorization-4" => "Fjxaaj2drg5wcZ8I7U",
  #     "X-Ops-Authorization-5" => "ffjXeiiiaHskkflllA",
  #     "X-Ops-Authorization-6" => "FjxJfjkskqkfjghAjQ=="
  #   }
  #
  # Returns a Hash with the necessary headers.
  def headers(body, method)
    body      = body
    #timestamp = Time.now.utc.iso8601
    #key       = OpenSSL::PKey::RSA.new(File.read(key_file))
    #canonical = "Method:#{method}\nHashed Path:#{encode(path)}\nX-Ops-Content-Hash:#{encode(body)}\nX-Ops-Timestamp:#{timestamp}\nX-Ops-UserId:#{client_name}"

    header_hash = {
      'Accept' => 'application/json',
      "Authorization" => "Bearer " + @@api_key,
      'Content-Type' => 'application/json'
    }

    #signature = Base64.encode64(key.private_encrypt(canonical))
    #signature_lines = signature.split(/\n/)
    #signature_lines.each_index do |idx|
      #key = "X-Ops-Authorization-#{idx + 1}"
      #header_hash[key] = signature_lines[idx]
    #end

    header_hash
  end
end
# chef_url = 'https://<ip>/organizations/default'
# chef_url = 'https://chef-compliance.local/api'
# chef = ComplianceAPI.new(server: chef_url, port: 443, ssl_insecure: true, client_name: 'admin', password: 'admin')
#
# puts chef.get_request('/version', '')

#puts chef.delete_request('/organizations/test1', '')
# puts chef.delete_request('/organizations/secure', "")

# puts chef.get_request('/organizations/default/cookbooks', "")
# puts chef.get_request('/organizations/test1/nodes', "")

# test = { 'name' => 'test1', 'full_name' => 'major test1' }
# resp =  chef.post_request('/organizations', test.to_json)
# puts resp
# File.open("#{resp['clientname']}.pem", 'w') { |file| file.write(resp['private_key']) }
#
# puts 'Users in org: '
# puts chef.get_request('/organizations/test1/users', '')
# puts chef.post_request('/organizations/test1/association_requests', { 'user' => 'admin' }.to_json)
# resp =  chef.get_request('/organizations/test1/association_requests', '')
# id = resp.find { |x| x['username'] == 'admin' }['id']
# puts chef.put_request("/users/admin/association_requests/#{id}", { 'response' => 'accept' }.to_json)
# puts 'Users in org: '
# puts chef.get_request('/organizations/test1/users', '')

# puts chef.post_request('/organizations', {"name" => "secure", "full_name" => 'secure test1'}.to_json)

end end

Chef::Recipe.send(:include, LearnChef::Compliance)
