module EasterEggs
	extend Discordrb::Commands::CommandContainer
	
	command(:bepis) do |event|
		break unless check_event(event)
		msg = File.readlines(File.join($config["moduledir"], "eastereggs", "bepis.txt")).sample
		event.respond msg.gsub('\n', "\n")
	end
	
end