module HAProxyCTL
  module Environment
    attr_accessor :pidof, :config_path, :config, :exec

    def version
      puts "HAProxyCTL #{HAProxyCTL::VERSION}"
    end

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
      @exec ||= `which haproxy`.chomp

      if @exec.empty?
        begin
          `haproxy -v 2>/dev/null`
          @exec = 'haproxy'
        rescue Errno::ENOENT => e
          @exec = nil
        end
      end

      (@exec)
    end

    def socket
      @socket ||= begin
        config.match /stats\s+socket \s*([^\s]*)/
        Regexp.last_match[1] || fail("Expecting 'stats socket <UNIX_socket_path>' in #{config_path}")
      end
    end

    def pidfile
      if config.match(/pidfile \s*([^\s]*)/)
        @pidfile = Regexp.last_match[1]
      else
        std_pid = '/var/run/haproxy.pid'
        if File.exists?(std_pid)
          @pidfile = std_pid
        else
          fail("Expecting 'pidfile <pid_file_path>' in #{config_path} or a pid file in #{std_pid}")
        end
      end
    end

    # @return [String, nil] Returns the PID of HAProxy as a string, if running. Nil otherwise.
    def check_running
      if File.exists?(pidfile)
        pid = File.read(pidfile)
        pid.strip!
      end

      # verify this pid exists and is haproxy
      if pid =~ /^\d+$/ and `ps -p #{pid} -o cmd=` =~ /#{exec}/
        return pid
      end
    end
    alias_method :pidof, :check_running
  end
end
