module Discordrb
	class Message
    def initialize(data, bot)
      @bot = bot
      @content = data['content']
      @channel = bot.channel(data['channel_id'].to_i)
      @pinned = data['pinned']
      @tts = data['tts']
      @nonce = data['nonce']
      @mention_everyone = data['mention_everyone']

      @author = if data['author']
                  if data['author']['discriminator'] == ZERO_DISCRIM
                    # This is a webhook user! It would be pointless to try to resolve a member here, so we just create
                    # a User and return that instead.
                    Discordrb::LOGGER.debug("Webhook user: #{data['author']['id']}")
                    User.new(data['author'], @bot)
                  elsif @channel.private?
                    # Turn the message user into a recipient - we can't use the channel recipient
                    # directly because the bot may also send messages to the channel
                    Recipient.new(bot.user(data['author']['id'].to_i), @channel, bot)
                  else
                    member = @channel.server.member(data['author']['id'].to_i)
										####NEW####
										member = @bot.user(data['author']['id'].to_i) unless member
										####END####
                    Discordrb::LOGGER.warn("Member with ID #{data['author']['id']} not cached even though it should be.") unless member
                    member
                  end
                end

      @webhook_id = data['webhook_id'].to_i if data['webhook_id']

      @timestamp = Time.parse(data['timestamp']) if data['timestamp']
      @edited_timestamp = data['edited_timestamp'].nil? ? nil : Time.parse(data['edited_timestamp'])
      @edited = !@edited_timestamp.nil?
      @id = data['id'].to_i

      @emoji = []

      @mentions = []

      data['mentions'].each do |element|
        @mentions << bot.ensure_user(element)
      end if data['mentions']

      @role_mentions = []

      # Role mentions can only happen on public servers so make sure we only parse them there
      if @channel.text?
        data['mention_roles'].each do |element|
          @role_mentions << @channel.server.role(element.to_i)
        end if data['mention_roles']
      end

      @attachments = []
      @attachments = data['attachments'].map { |e| Attachment.new(e, self, @bot) } if data['attachments']

      @embeds = []
      @embeds = data['embeds'].map { |e| Embed.new(e, self) } if data['embeds']
    end
	end
end