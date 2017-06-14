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
        config.match /^\s*nbproc \s*(\d*)\s*/
        (Regexp.last_match && Regexp.last_match[1].to_i) || 1
      rescue
        1
      end
    end

    def load_server_state_from_file
      @load_server_state_from_file ||= begin
        config.match /^\s*load-server-state-from-file \s*(.*)/
        Regexp.last_match && Regexp.last_match[1] && Regexp.last_match[1].strip
      rescue
        nil
      end
    end

    def server_state_file
      @server_state_file ||= begin
        # we don't support writing local state files yet, only global
        return nil unless load_server_state_from_file == 'global'
        config.match /^\s*server-state-file \s*(.*)/
        state_file = Regexp.last_match && Regexp.last_match[1].strip
        return nil if !state_file
        return state_file if state_file.start_with?('/')
        config.match /^\s*server-state-base \s*(.*)/
        state_base = (Regexp.last_match && Regexp.last_match[1].strip) || Dir.pwd
        return File.join(state_base, state_file)
      rescue
        nil
      end
    end

    def socket(process = 1)
      process = 1 if process == 0
      @sockets ||= []
      @sockets[process] ||= begin
        # If the haproxy config is using nbproc > 1, we pick which socket to use based
        # on the stats socket process assignment. We expect each stats socket to be
        # assigned to a single process (we don't support ranges even though haproxy does).
        if nbproc > 1
          config.match /stats\s+socket \s*([^\s]*) \s*.*process \s*#{process}[\d^]?/
        else
          config.match /stats\s+socket \s*([^\s]*)/
        end
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

    def any_running(pids)
      return false if !pids || pids.empty?
      pids.any? { |pid| pid =~ /^\d+$/ and `ps -p #{pid} -o cmd=` =~ /#{exec}/ }
    end
  end
end
