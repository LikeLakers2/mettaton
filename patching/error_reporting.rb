module Discordrb::Events
	class EventHandler
		alias_method :orig_call, :call
		
		def call(*args)
			orig_call(*args)
		rescue => exc
			report(exc)
		end
	end
end

module Discordrb::Commands
	class Command
		alias_method :orig_call, :call
		
		def call(*args)
			orig_call(*args)
		rescue => exc
			report(exc)
		end
	end
end