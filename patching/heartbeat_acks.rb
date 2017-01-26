# This file uses code from Websocket::Client::Simple, licensed under the following license:
#
# Copyright (c) 2013-2014 Sho Hashimoto
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
#                                  distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'thread'

module Discordrb
  # This class stores the data of an active gateway session. Note that this is different from a websocket connection -
  # there may be multiple sessions per connection or one session may persist over multiple connections.
  class Session
    def initialize(session_id)
      @session_id = session_id
      @sequence = 0
      @suspended = false
      @invalid = false
    end

    def resume
      @suspended = false
    end
  end

  # Client for the Discord gateway protocol
  class Gateway
    # Heartbeat ACKs are Discord's way of verifying on the client side whether the connection is still alive. Setting
    # this to true will use that functionality to detect zombie connections and reconnect in such a case, however it may
    # lead to instability if there's some problem with the ACKs.
    # @return [true, false] whether or not this gateway should check for heartbeat ACKs.
    attr_accessor :check_heartbeat_acks

    def initialize(bot, token, shard_key = nil)
      @token = token
      @bot = bot

      @shard_key = shard_key

      @getc_mutex = Mutex.new

      # Whether the connection to the gateway has succeeded yet
      @ws_success = false
    end

    # Sends a heartbeat with the last received packet's seq (to acknowledge that we have received it and all packets
    # before it), or if none have been received yet, with 0.
    # @see #send_heartbeat
    def heartbeat
      if check_heartbeat_acks
        unless @last_heartbeat_acked
          # We're in a bad situation - apparently the last heartbeat wasn't acked, which means the connection is likely
          # a zombie. Reconnect
          LOGGER.warn('Last heartbeat was not acked, so this is a zombie connection! Reconnecting')

          # We can't send anything on zombie connections
          @pipe_broken = true
          reconnect
          return
        end

        @last_heartbeat_acked = false
      end

      send_heartbeat(@session ? @session.sequence : 0)
    end

    # Identifies to Discord with the default parameters.
    # @see #send_identify
    def identify
      send_identify(@token, {
                      :'$os' => RUBY_PLATFORM,
                      :'$browser' => 'discordrb',
                      :'$device' => 'discordrb',
                      :'$referrer' => '',
                      :'$referring_domain' => ''
                    }, true, 100, @shard_key)
    end

    # Sends an identify packet (op 2). This starts a new session on the current connection and tells Discord who we are.
    # This can only be done once a connection.
    # @param token [String] The token with which to authorise the session. If it belongs to a bot account, it must be
    #   prefixed with "Bot ".
    # @param properties [Hash<Symbol => String>] A list of properties for Discord to use in analytics. The following
    #   keys are recognised:
    #
    #    - "$os" (recommended value: the operating system the bot is running on)
    #    - "$browser" (recommended value: library name)
    #    - "$device" (recommended value: library name)
    #    - "$referrer" (recommended value: empty)
    #    - "$referring_domain" (recommended value: empty)
    #
    # @param compress [true, false] Whether certain large packets should be compressed using zlib.
    # @param large_threshold [Integer] The member threshold after which a server counts as large and will have to have
    #   its member list chunked.
    # @param shard_key [Array(Integer, Integer), nil] The shard key to use for sharding, represented as
    #   [shard_id, num_shards], or nil if the bot should not be sharded.
    def send_identify(token, properties, compress, large_threshold, shard_key = nil)
      data = {
        # Don't send a v anymore as it's entirely determined by the URL now
        token: token,
        properties: properties,
        compress: compress,
        large_threshold: large_threshold
      }

      # Don't include the shard key at all if it is nil as Discord checks for its mere existence
      data[:shard] = shard_key if shard_key

      send_packet(Opcodes::IDENTIFY, data)
    end

    # Resumes the session from the last recorded point.
    # @see #send_resume
    def resume
      send_resume(@token, @session.session_id, @session.sequence)
    end

    # Reconnects the gateway connection in a controlled manner.
    # @param attempt_resume [true, false] Whether a resume should be attempted after the reconnection.
    def reconnect(attempt_resume = true)
      @session.suspend if attempt_resume

      @instant_reconnect = true
      @should_reconnect = true

      close
    end

    private

    def setup_heartbeats(interval)
      # Make sure to reset ACK handling, so we don't keep reconnecting
      @last_heartbeat_acked = true

      # If we suspended the session before because of a reconnection, we need to resume it now
      @session.resume if @session && @session.suspended?

      # We don't want to have redundant heartbeat threads, so if one already exists, don't start a new one
      return if @heartbeat_thread

      @heartbeat_interval = interval
      @heartbeat_thread = Thread.new do
        Thread.current[:discordrb_name] = 'heartbeat'
        loop do
          begin
            # Send a heartbeat if heartbeats are active and either no session exists yet, or an existing session is
            # suspended (e.g. after op7)
            if (@session && !@session.suspended?) || !@session
              sleep @heartbeat_interval
              @bot.raise_heartbeat_event
              heartbeat
            else
              sleep 1
            end
          rescue => e
            LOGGER.error('An error occurred while heartbeating!')
            LOGGER.log_exception(e)
          end
        end
      end
    end

    def connect_loop
      # Initialize falloff so we wait for more time before reconnecting each time
      @falloff = 1.0

      @should_reconnect = true
      loop do
        connect

        break unless @should_reconnect

        if @instant_reconnect
          LOGGER.info('Instant reconnection flag was set - reconnecting right away')
          @instant_reconnect = false
        else
          wait_for_reconnect
        end

        # Restart the loop, i. e. reconnect
      end
    end

    def handle_message(msg)
      if msg.byteslice(0) == 'x'
        # The message is compressed, inflate it
        msg = Zlib::Inflate.inflate(msg)
      end

      # Parse packet
      packet = JSON.parse(msg)
      op = packet['op'].to_i

      LOGGER.in(packet)

      # If the packet has a sequence defined (all dispatch packets have one), make sure to update that in the
      # session so it will be acknowledged next heartbeat.
      # Only do this, of course, if a session has been created already; for a READY dispatch (which has s=0 set but is
      # the packet that starts the session in the first place) we need not do any handling since initialising the
      # session will set it to 0 by default.
      @session.sequence = packet['s'] if packet['s'] && @session

      case op
      when Opcodes::DISPATCH
        handle_dispatch(packet)
      when Opcodes::HELLO
        handle_hello(packet)
      when Opcodes::RECONNECT
        handle_reconnect
      when Opcodes::INVALIDATE_SESSION
        handle_invalidate_session
      when Opcodes::HEARTBEAT_ACK
        handle_heartbeat_ack(packet)
      when Opcodes::HEARTBEAT
        handle_heartbeat(packet)
      else
        LOGGER.warn("Received invalid opcode #{op} - please report with this information: #{msg}")
      end
    end

    # Op 0
    def handle_dispatch(packet)
      data = packet['d']
      type = packet['t'].intern

      case type
      when :READY
        LOGGER.info("Discord using gateway protocol version: #{data['v']}, requested: #{GATEWAY_VERSION}")

        @session = Session.new(data['session_id'])
        @session.sequence = 0
      when :RESUMED
        # The RESUMED event is received after a successful op 6 (resume). It does nothing except tell the bot the
        # connection is initiated (like READY would). Starting with v5, it doesn't set a new heartbeat interval anymore
        # since that is handled by op 10 (HELLO).
        LOGGER.good 'Resumed'
        return
      end

      @bot.dispatch(type, data)
    end

    # Op 1
    def handle_heartbeat(packet)
      # If we receive a heartbeat, we have to resend one with the same sequence
      send_heartbeat(packet['s'])
    end

    # Op 7
    def handle_reconnect
      LOGGER.debug('Received op 7, reconnecting and attempting resume')
      reconnect
    end

    # Op 11
    def handle_heartbeat_ack(packet)
      LOGGER.debug("Received heartbeat ack for packet: #{packet.inspect}")
      @last_heartbeat_acked = true if @check_heartbeat_acks
    end

    def send(data, type = :text)
      LOGGER.out(data)

      unless @handshaked && !@closed
        # If we're not handshaked or closed, it means there's no connection to send anything to
        raise 'Tried to send something to the websocket while not being connected!'
      end

      # Create the frame we're going to send
      frame = ::WebSocket::Frame::Outgoing::Client.new(data: data, type: type, version: @handshake.version)

      # Try to send it
      begin
        @socket.write frame.to_s
      rescue => e
        # There has been an error!
        @pipe_broken = true
        handle_internal_close(e)
      end
    end
  end
end
