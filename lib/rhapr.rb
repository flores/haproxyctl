require 'rhapr/version'
require 'rhapr/environment'

module Rhapr
  autoload :CLI,            'rhapr/cli'
  autoload :ServiceRunner,  'rhapr/service_runner'
  autoload :SocketRunner,   'rhapr/socket_runner'
end
