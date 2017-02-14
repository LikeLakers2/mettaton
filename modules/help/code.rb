module HelpCommand
	extend Discordrb::Commands::CommandContainer
	
	command(:help) do |event|
		break unless check_event(event)
		help_cmd
	end
	
	def self.help_cmd
		"My help listing has been moved to https://github.com/LikeLakers2/mettaton/wiki"
	end
end