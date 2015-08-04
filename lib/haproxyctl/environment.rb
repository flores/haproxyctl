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

    def nbproc 
      @nbproc ||= begin
        config.match /nbproc \s*(\d*)\s*/
        Regexp.last_match(1).to_i || 1
      end
    end

    def sockets
      # Always capture socket path, and include process id if it exists.
      # Note: whoever runs haproxy with nbprocs > 1 and has a socket listener without process id .. can blame themself.
      @sockets = Hash[config.scan(/stats\s+socket\s+([^\[\s\]]*)(?:(?:.*process)?(?:.*process\s+([^\[\s\]]*)))?/).collect { |v| [v[1].to_i,v[0]] }]
      @sockets.empty? && fail(RuntimeError.new "Expecting 'stats socket <UNIX_socket_path>' in #{config_path}")
      @sockets
    end

    def pidfile
      if config.match(/pidfile \s*([^\s]*)/)
        @pidfile = Regexp.last_match(1)
      else
        std_pid = '/var/run/haproxy.pid'
        if File.exists?(std_pid)
          @pidfile = std_pid
        else
          fail("Expecting 'pidfile <pid_file_path>' in #{config_path} or a pid file in #{std_pid}")
        end
      end
    end

    # @return [Array, nil] Returns the PIDs of HAProxy as an Array, if running. Nil otherwise.
    def check_running
      if File.exists?(pidfile)
        pid = File.read(pidfile)
        pids = pid.strip.split("\n")
      end

      # verify these pid(s) exists and are haproxy
      if pids and pids.all? { |pid| pid =~ /^\d+$/ and `ps -p #{pid} -o cmd=` =~ /#{exec}/ }
        return pids
      end
    end
    alias_method :pidof, :check_running
  end
end
