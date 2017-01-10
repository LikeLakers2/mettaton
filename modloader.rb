
###                                                                    ###
# Module loader for the bot. Nothing special, just means I don't have to #
#  change a require_relative list every time I want to add a new thing.  #
###                                                                    ###

puts "Loading modules..."

$mods ||= []
Dir.glob($config["moduledir"]+"/*.rb") { |mod|
	puts "Loading ./#{mod}"
	require_relative "./#{mod}"
}

$mods.each { |mod| $bot.include! mod }

puts "Loading modules successful."
