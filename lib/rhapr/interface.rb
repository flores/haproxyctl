require 'socket'

module Rhapr
  class Interface
    include Rhapr::Environment

    def initialize
      # @todo: Do.
    end

    def clear_counters
      send 'clear counters'
    end
    alias :clear :clear_counters

    # @param [String, #to_s] message The message to be sent to HAProxy
    # return [Array<String>] All of the output from HAProxy, read in.
    # @see Rhapr::Interface#write, Rhapr::Interface#read_full
    def send(message)
      sock = socket

      write(sock, message)
      read_full(sock)
    end

   protected
    # @param [UNIXSocket]
    # @param [String]
    # @return [nil]
    def write(socket, message)
      socket.puts message
    end

    # @return [String]
    def read(socket)
      socket.gets
    end

    # @return [Array<String>] All of the output from HAProxy, read in.
    # @see Rhapr::Interface#read
    def read_full(socket)
      output = []
      output << read(socket) until(sock.eof?)
    end
  end
end
