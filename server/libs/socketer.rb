##
# socketer.rb
# Created November 27, 2015
# By Ron Bowes
#
# See: LICENSE.md
#
# This is a fairly simple wrapper around TCPSocket that makes the interface
# a bit more ruby-esque.
##

require 'socket'

class Socketer
  BUFFER = 65536

  class Session
    def initialize(client, callbacks = {})
      @client     = client
      @on_connect = callbacks[:on_connect]
      @on_data    = callbacks[:on_data]
      @on_error   = callbacks[:on_error]

      # Do the 'new connection' callback
      if(@on_connect)
        @on_connect.call(self, client.peeraddr[2], client.peeraddr[1])
      end
    end

    def _handle_exception(e, msg)
      if(@on_error)
        @on_error.call(self, "Error #{msg}: #{e}", e)
      end
      stop!()
    end

    def ready!()
      @thread = Thread.new() do
        begin
          loop do
            data = @client.recv(BUFFER)

            if(data.nil? || data.length == 0)
              raise(IOError, "Connection closed")
            end

            if(@on_data)
              @on_data.call(self, data)
            end
          end
        rescue Exception => e
          begin
            _handle_exception(e, "receiving data")
          rescue Exception => e
            puts("Error in exception handler; please don't do that :)")
            puts(e)
            puts(e.backtrace)
          end
        end
      end
    end

    def stop!()
      if(@thread)
        @thread.exit()
      end

      @client.close()
    end

    def send(data)
      begin
        @client.write(data)
      rescue Exception => e
        _handle_exception(e, "sending data")

        stop!()
      end
    end
  end

  def Socketer.listen(host, port, callbacks = {})
    # Create the socket right away so we'll know if it fails
    #puts("Listening on #{host}:#{port}...")
    s = TCPServer.new(host, port)

    return Thread.new() do
      loop do
        # TODO: begin
        Session.new(s.accept(), callbacks)
      end
    end
  end

  def Socketer.connect(host, port, callbacks = {})
    #puts("Connecting to #{host}:#{port}...")

    return Thread.new() do
      begin
        s = TCPSocket.new(host, port)
        if(s)
          Session.new(s, callbacks)
        else
          if(callbacks[:on_error])
            callbacks[:on_error].call(nil, "Couldn't connect to #{host}:#{port}!")
          end
        end
      rescue Exception => e
        _handle_exception(e, "connecting to #{host}:#{port}")
      end
    end
  end
end
