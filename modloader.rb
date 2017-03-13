puts "Loading modules..."

$mods ||= []
Dir.glob($config["moduledir"]+"/*.rb") { |mod|
	puts "Loading ./#{mod}"
	require_relative "./#{mod}"
}

$mods.each { |mod| $bot.include! mod }

puts "Loading modules successful."
