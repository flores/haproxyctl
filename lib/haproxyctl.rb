require 'haproxyctl/environment'

module HAProxyCTL
  include Environment

  def start
    puts "starting haproxy..."
    system("#{exec} -f #{config_path} -D -p #{pid}")
    newpidof = `pidof haproxy`.chomp
    if ( newpidof =~ /\d+/ )
      puts "haproxy is running on pid #{newpidof}"
      return true
    else
      puts "error.  haproxy did not start!"
      return nil
    end
  end

  def stop(pid)
    if pid
      puts "stopping haproxy on pid #{pid}..."
      system("kill #{pid}") || system("killall haproxy")
      puts "... stopped"
    else
      puts "haproxy is not running!"
    end
  end

  def reload(pid)
    if ( pid )
      puts "gracefully stopping connections on pid #{pid}..."
      system("#{exec} -f #{config_path} -sf #{pid}")
      puts "checking if connections still alive on #{pid}..."
      nowpid = check_running()
      while ( pid == nowpid )
        puts "still haven't killed old pid.
                            waiting 2s for existing connections to die...
                            (ctrl+c to stop this check)"
        sleep 2
        nowpid = check_running() || 0
      end
      puts "reloaded haproxy on pid #{nowpid}"
    else
      puts "haproxy is not running!"
    end
  end

  def unixsock(command)
    require 'socket'

    output=[]

    ctl=UNIXSocket.open(socket)
    ctl.puts "#{command}"
    while (line = ctl.gets) do
      unless ( line =~ /Unknown command/ )
        output << line
      end
    end
    ctl.close

    return output
  end

  def display_usage!
    puts usage
    exit
  end

  def usage
    <<-USAGE
usage: #{$0} <argument>
  where argument can be:
    start                     : start haproxy unless it is already running
    stop                      : stop an existing haproxy
    restart                   : immediately shutdown and restart
    reload                    : gracefully terminate existing connections, reload #{config_path}
    status                    : is haproxy running?  on what ports per lsof?
    configcheck               : check #{config_path}
    nagios                    : nagios-friendly status for running process and listener
    cloudkick                 : cloudkick.com-friendly status and metric for connected users
    show health               : show status of all frontends and backend servers
    enable all server         : re-enable a server previously in maint mode on multiple backends
    disable all server        : disable a server from every backend it exists
    enable all EXCEPT server  : like 'enable all', but re-enables every backend except for <server>
    disable all EXCEPT server : like 'disable all', but disables every backend except for <server>"
USAGE
  end
end
