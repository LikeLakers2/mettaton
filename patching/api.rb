module Discordrb
  module API
    # Make a splash URL from server and splash IDs
    def splash_url(server_id, splash_id)
      "https://cdn.discordapp.com/splashes/#{server_id}/#{splash_id}.jpg"
    end
  end

  class Server
    # @return [Array<Integration>] an array of all the integrations connected to this server.
    def integrations
      integration = JSON.parse(API::Server.integrations(@bot.token, @id))
      integration.map { |element| Integration.new(element, @bot, self) }
    end

    # Cache @embed
    # @note For internal use only
    # @!visibility private
    def cache_embed
      @embed ||= JSON.parse(API::Server.resolve(@bot.token, @id))['embed_enabled']
    end

    # @return [String] the hexadecimal ID used to identify this server's splash image for their VIP invite page.
    def splash_id
      @splash_id ||= JSON.parse(API::Server.resolve(@bot.token, @id))['splash']
    end
  end
end 