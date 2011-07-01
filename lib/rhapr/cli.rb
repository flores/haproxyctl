module Rhapr
  class CLI
    include Environment

    def initialize(*args)
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
end
