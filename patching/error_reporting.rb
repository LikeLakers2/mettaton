module Discordrb::Events
	class EventHandler
		def call(event)
			@block.call(event)
		rescue => exc
			report(exc)
		end
	end
end

module Discordrb::Commands
	class Command
		def call(event, arguments, chained = false, check_permissions = true)
			if arguments.length < @attributes[:min_args]
				event.respond "Too few arguments for command `#{name}`!"
				event.respond "Usage: `#{@attributes[:usage]}`" if @attributes[:usage]
				return
			end
			if @attributes[:max_args] >= 0 && arguments.length > @attributes[:max_args]
				event.respond "Too many arguments for command `#{name}`!"
				event.respond "Usage: `#{@attributes[:usage]}`" if @attributes[:usage]
				return
			end
			unless @attributes[:chain_usable]
				if chained
					event.respond "Command `#{name}` cannot be used in a command chain!"
					return
				end
			end

			if check_permissions
				rate_limited = event.bot.rate_limited?(@attributes[:bucket], event.author)
				if @attributes[:bucket] && rate_limited
					if @attributes[:rate_limit_message]
						event.respond @attributes[:rate_limit_message].gsub('%time%', rate_limited.round(2).to_s)
					end
					return
				end
			end

			result = @block.call(event, *arguments)
			event.drain_into(result)
		rescue LocalJumpError # occurs when breaking
			nil
		rescue => exc
			report(exc)
		end
	end
end