require 'socket'

module Rhapr
  module Environment
    attr_reader :haproxy_pid, :config_path, :config, :exec, :socket_path

    # @return [String, nil] The path to the HAProxy configuration file, or nil if not found. Set the ENV variable $HAPROXY_CONFIG to override defaults.
    def config_path
      return(@config_path) if @config_path

      if ENV['HAPROXY_CONFIG']
        @config_path = ENV['HAPROXY_CONFIG']
      else
        config_paths = %w{/etc/haproxy/haproxy.cfg /etc/haproxy.cfg /usr/local/etc/haproxy.cfg}
        config_paths.select! { |cfg| File.exists?(cfg) }

        @config_path = config_paths.first
      end

      (@config_path)
    end

    # @return [String] The raw contents of the HAProxy configuration file.
    # @raise [RuntimeError] If it cannot read the contents of #config_path.
    def config
      @config ||= begin
                    File.read(config_path)
                  rescue Errno::ENOENT => e
                    raise RuntimeError.new("Error openning file '#{config_path}'. Exception from File.read: #{e.exception}")
                  end
    end

    # @return [true, false] Whether or not the HAProxy executable can be found.
    # @see Rhapr::Environment#exec
    def has_exec?
      !exec.nil?
    end

    # @return [String, nil] The path to the HAProxy executable will be returned, if found. Set ENV variable $HAPROXY_BIN to override
    def exec
      return(@exec) if @exec

      @exec   = ENV['HAPROXY_BIN']
      @exec ||= `which haproxy`

      if @exec.empty?
        begin
          `haproxy -v`
          @exec = 'haproxy'
        rescue Errno::ENOENT => e
          @exec = nil
        end
      end

      (@exec)
    end

    # @return [UNIXSocket] A connection to the HAProxy Socket
    # @raise [RuntimeError] Raised if a socket connection could not be established
    def socket
      begin
        UNIXSocket.open(socket_path)
      rescue Errno::EACCES => e
        raise RuntimeError.new("Could not open a socket with HAProxy. Error message: #{e.message}")
      end
    end

    # @return [String] The path to the HAProxy stats socket.
    # @raise [RuntimeError] Raised if no stats socket has been specified, in the HAProxy configuration.
    # @todo: Should there be an ENV var for this? Perhaps allow config-less runs of rhapr?
    def socket_path
      @socket_path  ||= begin
                          config.match /stats\s+socket\s+([^\s]*)/
                          Regexp.last_match[1] || fail(RuntimeError.new "Expecting 'stats socket <UNIX_socket_path>' in #{config_path}")
                        end
    end

    # @return [String] Returns the path to the pidfile, specified in the HAProxy configuration. Returns an assumption, if not found.
    # @todo: Should there even be an assumption? Does HAProxy create a pid file, if not told to by the configuration?
    # @todo: Should there be an ENV var for this? Perhaps allow config-less runs of rhapr?
    def pid
      @pid  ||= begin
                  config.match /pidfile ([^\s]*)/
                  Regexp.last_match[1] || '/var/run/haproxy.pid'
                end
    end

    # @return [String, nil] Returns the PID of HAProxy as a string, if running. Nil otherwise.
    # @todo: Look for something other than pidof, for searching the process list.
    #   Could read from the pid file, but there's potential that it will go stale.
    def check_running
      pidof = `pidof haproxy`
      pidof.strip!

      return pidof unless pidof.empty?
    end
    alias_method :pidof, :check_running
  end
end
