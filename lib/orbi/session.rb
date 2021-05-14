require 'net/http'
require 'uri'
require 'json'
require 'logger'

module Orbi
  # Class to hold the Orbi session the rest of the API needs to access the router
  class Session
    # @return [URI::HTTP] Orbi router
    attr_accessor :uri

    # @return [String] xsrf token required for all calls ot the router
    attr_accessor :xsrf_token

    def initialize(xsrf_token, uri)
      self.xsrf_token = xsrf_token
      self.uri = uri

      status
    end

    def logout
      logger ||= Logger.new($stdout)
      logout_uri = uri.scheme == 'https' ? URI::HTTPS.build(host: uri.host, path: '/LGO_logout.htm') : URI::HTTP.build(host: uri.host, path: '/LGO_logout.htm')
      begin
        http = Net::HTTP.new(logout_uri.host, logout_uri.port)
        request = Net::HTTP::Get.new(logout_uri.request_uri)
        request['Cookie'] = xsrf_token

        response = http.request request # Net::HTTPResponse object
        logger.info "Login failed: #{response.body}"

        self.uri = nil
        self.xsrf_token = nil
      rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
        logger.error "Login failed: #{e.messages}"
      end
      nil
    end

    def status
      !xsrf_token.nil?
    end

    def self.login(host, username, password, https: false, logger: nil)
      raise 'host should not be nil' if host.nil?
      raise 'username should not be nil' if username.nil?

      logger ||= Logger.new($stdout)
      xsrf_token = retrieve_token host, https, logger: logger

      begin
        uri = https ? URI::HTTPS.build(host: host, path: '/start.htm') : URI::HTTP.build(host: host, path: '/start.htm')

        # Create the HTTP objects
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.request_uri)
        request.basic_auth username, password
        request['Cookie'] = xsrf_token

        response = http.request request # Net::HTTPResponse object
        return Session.new(xsrf_token, uri) if response.code == '200'

        logger.error "Login failed: #{response.body}"

      rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
        logger.error "Login failed: #{e.messages}"
      end
      nil
    end

    #
    # Retrieve the XSRF token that the omni router requires on every request.
    #
    # @param [<Type>] host IP/Hostname of the router to connect to 
    # @param [<Type>] https if true, then the connection will be made over https
    # @param [<Type>] logger Logger to log progress/output
    #
    # @return [<Type>] xsrf token or nil if it cannot be retrieved
    #
    def self.retrieve_token(host, https, logger: nil)
      begin
        logger ||= Logger.new($stdout)
        uri = https ? URI::HTTPS.build(host: host, path: '/start.htm') : URI::HTTP.build(host: host, path: '/start.htm')

        # Create the HTTP objects
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.request_uri)

        response = http.request request # Net::HTTPResponse object
        xsrf_token = response.response['set-cookie'].split(';').select { |i| i.strip.start_with? 'XSRF' }.first
        logger.info "XSRF Token: #{xsrf_token}"
        return xsrf_token
      rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
        logger.error "Failed to retrieve xsrf token: #{e.messages}"
      end
      nil
    end
  end
end
