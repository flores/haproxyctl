require 'haproxyctl/version'
require 'haproxyctl/environment'
require 'socket'

module HAProxyCTL
  include Environment

  def start
    puts 'starting haproxy...'
    system("#{exec} -f #{config_path} -D -p #{pidfile}")
    newpids = check_running
    if newpids.all? {|newpid| newpid =~ /^\d+$/} 
      puts "haproxy is running on pid #{newpids.join(', ')}"
      return true
    else
      puts 'error. haproxy did not start!'
      return nil
    end
  end

  def stop(pids)
    if pids
      puts "stopping haproxy on pids #{pids.join(', ')}..."
      pids.each { |pid| system("kill #{pid}") || system("kill -9 #{pid}") }
      puts '... stopped'
    else
      puts 'haproxy is not running!'
    end
  end

  def reload(pids)
    if pids
      puts "gracefully stopping connections on pids #{pids.join(', ')}..."
      system("#{exec} -D -f #{config_path} -p #{pidfile} -sf $(cat #{pidfile})")
      puts "checking if connections still alive on #{pids.join(', ')}..."
      nowpids = check_running
      while pids == nowpids
        puts "still haven't killed old pids.
                            waiting 2s for existing connections to die...
                            (ctrl+c to stop this check)"
        sleep 2
        nowpids = check_running || 0
      end
      puts "reloaded haproxy on pids #{nowpids.join(', ')}"
    else
      puts 'haproxy is not running!'
    end
  end

  def unixsock(command)
    output = []
    runs = 0

    begin
      ctl = UNIXSocket.open(socket)
      if ctl
        ctl.write "#{command}\r\n"
      else
        puts "cannot talk to #{socket}"
      end
    rescue Errno::EPIPE
      ctl.close
      sleep 0.5
      runs += 1
      if  runs < 4
        retry
      else
        puts "the unix socket at #{socket} closed before we could complete this request"
        exit
      end
    end
    while (line = ctl.gets)
      unless  line =~ /Unknown command/
        output << line
      end
    end
    ctl.close

    output
  end

  def display_usage!
    puts usage
    exit
  end

  def usage
    <<-USAGE
usage: #{$PROGRAM_NAME} <argument>
  where <argument> can be:
    start                       : start haproxy unless it is already running
    stop                        : stop an existing haproxy
    restart                     : immediately shutdown and restart
    reload                      : gracefully terminate existing connections, reload #{config_path}
    status                      : is haproxy running?  on what ports per lsof?
    configcheck                 : check #{config_path}
    nagios                      : nagios-friendly status for running process and listener
    cloudkick                   : cloudkick.com-friendly status and metric for connected users
    show health                 : show status of all frontends and backend servers
    show backends               : show status of backend pools of servers
    enable all <server>         : re-enable a server previously in maint mode on multiple backends
    disable all <server>        : disable a server from every backend it exists
    enable all EXCEPT <server>  : like 'enable all', but re-enables every backend except for <server>
    disable all EXCEPT <server> : like 'disable all', but disables every backend except for <server>
    clear counters              : clear max statistics counters (add 'all' for all counters)
    help                        : this message
    prompt                      : toggle interactive mode with prompt
    quit                        : disconnect
    show info                   : report information about the running process
    show stat                   : report counters for each proxy and server
    show errors                 : report last request and response errors for each proxy
    show sess [id]              : report the list of current sessions or dump this session
    get weight                  : report a server's current weight
    set weight                  : change a server's weight
    set timeout                 : change a timeout setting
    disable server              : set a server in maintenance mode
    enable server               : re-enable a server that was previously in maintenance mode
    version                     : version of this script
USAGE
  end
end
