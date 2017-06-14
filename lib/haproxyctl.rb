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
      write_server_state_file
      puts "stopping haproxy on pids #{pids.join(', ')}..."
      pids.each { |pid| system("kill #{pid}") || system("kill -9 #{pid}") }
      puts '... stopped'
    else
      puts 'haproxy is not running!'
    end
  end

  def reload(pids)
    unless pids
      puts 'haproxy is not running!'
      return
    end
    write_server_state_file
    pids_string = pids.join(' ')
    puts "gracefully stopping connections on pids #{pids_string}..."
    reload_succeeded = system("#{exec} -D -f #{config_path} -p #{pidfile} -sf $(cat #{pidfile})")
    puts "checking if connections still alive on #{pids_string}..."
    nowpids = check_running
    if !reload_succeeded
      puts "pids no longer exist, haproxy may no longer be running" unless pids == nowpids
      puts "failed to reload haproxy, check errors above"
      return
    end
    while pids == nowpids
      puts "still haven't killed old pids.
                          waiting 2s for existing connections to die...
                          (ctrl+c to stop this check)"
      sleep 2
      nowpids = check_running || 0
    end
    puts "reloaded haproxy on pids #{nowpids.join(', ')}"
  end

  def reload_kill_zombies(pids, seconds_to_wait)
    unless pids
      puts 'haproxy is not running!'
      return
    end
    write_server_state_file
    pids_string = pids.join(' ')
    puts "gracefully stopping connections on pids #{pids_string}..."
    reload_succeeded = system("#{exec} -D -f #{config_path} -p #{pidfile} -sf #{pids_string}")
    puts "checking if connections still alive on #{pids_string}..."
    nowpids = check_running
    if !reload_succeeded
      puts "pids no longer exist, haproxy may no longer be running" unless pids == nowpids
      puts "failed to reload haproxy, check errors above"
      return
    end
    while pids == nowpids
      puts "still haven't killed old pids.
                          waiting 2s for existing connections to die...
                          (ctrl+c to stop this check)"
      sleep 2
      nowpids = check_running || 0
    end
    puts "reloaded haproxy on pids #{nowpids.join(', ')}"
    puts "ensuring that old pids aren't zombies"
    seconds_waited = 0
    termed = false
    while any_running pids
      if seconds_waited >= seconds_to_wait
        puts "waited #{seconds_waited} for old pids to exit.
                          they did not die gracefully.
                          terminating #{pids_string}"
        if termed
          puts "SIGTERM didn't work, killing #{pids_string}"
          system("kill -9 #{pids_string} 2> /dev/null")
        else
          system("kill #{pids_string} 2> /dev/null")
          termed = true
        end
      else
        puts "old pids still alive.
                          waiting 2s and checking again"
        sleep 2
        seconds_waited = seconds_waited + 2
      end
    end
  end

  def write_server_state_file
    return unless server_state_file
    begin
      File.open(server_state_file, 'w') do |f|
        (1..nbproc).each do |i|
          f.puts(unixsock('show servers state', i))
        end
      end
    end
  end

  def unixsock(command, process)
    output = []
    runs = 0

    begin
      ctl = UNIXSocket.open(socket(process))
      if ctl
        ctl.write "#{command}\r\n"
      else
        puts "cannot talk to #{socket(process)}"
      end
    rescue Errno::EPIPE
      ctl.close
      sleep 0.5
      runs += 1
      if  runs < 4
        retry
      else
        puts "the unix socket at #{socket(process)} closed before we could complete this request"
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
    start                               : start haproxy unless it is already running
    stop                                : stop an existing haproxy
    restart                             : immediately shutdown and restart
    reload                              : gracefully terminate existing connections, reload #{config_path}
    status                              : is haproxy running?  on what ports per lsof?
    configcheck                         : check #{config_path}
    nagios                              : nagios-friendly status for running process and listener
    <proc?> show health                 : show status of all frontends and backend servers
    <proc?> show backends               : show status of backend pools of servers
    <proc?> enable all <server>         : re-enable a server previously in maint mode on multiple backends
    <proc?> disable all <server>        : disable a server from every backend it exists
    <proc?> drain all <server>          : drain a server from every backend it exists
    <proc?> enable all EXCEPT <server>  : like 'enable all', but re-enables every backend except for <server>
    <proc?> disable all EXCEPT <server> : like 'disable all', but disables every backend except for <server>
    <proc?> drain all EXCEPT <server>   : like 'drain all', but drains every backend except for <server>
    <proc?> clear counters              : clear max statistics counters (add 'all' for all counters)
    help                                : this message
    prompt                              : toggle interactive mode with prompt
    quit                                : disconnect
    <proc?> show info                   : report information about the running process
    <proc?> show stat                   : report counters for each proxy and server
    <proc?> show errors                 : report last request and response errors for each proxy
    <proc?> show sess [id]              : report the list of current sessions or dump this session
    <proc?> get weight                  : report a server's current weight
    <proc?> set weight                  : change a server's weight
    <proc?> set timeout                 : change a timeout setting
    <proc?> disable server              : set a server in maintenance mode
    <proc?> enable server               : re-enable a server that was previously in maintenance mode
    version                             : version of this script

  <proc?> is an optional numerical argument that selects the process number to target
    - only applicable when nbproc > 1
    - defaults to 1
USAGE
  end
end
