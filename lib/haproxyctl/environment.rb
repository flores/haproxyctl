module HAProxyCTL
  module Environment
    attr_accessor :pidof, :config_path, :config, :exec

    def config_path
      @config_path ||= ENV['HAPROXY_CONFIG'] || '/etc/haproxy/haproxy.cfg'
    end

    def config
      @config ||= File.read(config_path)
    end

    def has_exec?
      !exec.nil?
    end

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

      return(@exec)
    end

    def socket
      @socket ||= begin
        config.match /stats socket ([^\s]*)/
        $1 || raise("Expecting 'stats socket <UNIX_socket_path>' in #{config_path}")
      end
    end

    def pid
      config.match /pidfile ([^\s]*)/
      @pid = $1 || '/var/run/haproxy.pid'
    end

    # @return [String, nil] Returns the PID of HAProxy as a string, if running. Nil otherwise.
    def check_running
      pidof = `pidof haproxy`
      pidof.strip!

      return pidof if pidof =~ /^\d+$/
    end
    alias :pidof :check_running
  end
end
