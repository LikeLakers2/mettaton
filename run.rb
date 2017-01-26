#Load configs first before we do anything
require_relative './configloader'

#Load discordrb and create the bot instance
require 'discordrb'
#Patching
Dir.glob("./patching/*.rb") { |mod|
	puts "Patching with ./#{mod}"
	require_relative "./#{mod}"
}

AF_FIVE_NUL = "\0"*5
$bot = Discordrb::Commands::CommandBot.new token: $credentials["token"], client_id: $credentials["client_id"],
			prefix: $libconfig["prefix"], fancy_log: $libconfig["fancy_log"], ignore_bots: $libconfig["ignore_bots"],
			webhook_commands: $libconfig["webhook_commands"],
			spaces_allowed: true, parse_self: true, help_command: false, command_doesnt_exist_message: false,
			#I don't want anything but "quote_start" and "quote_end" but it glitches out with empty strings
			advanced_functionality: true, previous: "#{AF_FIVE_NUL}~", chain_delimiter: "#{AF_FIVE_NUL}>",
			chain_args_delim: "#{AF_FIVE_NUL}:", sub_chain_start: "#{AF_FIVE_NUL}[", sub_chain_end: "#{AF_FIVE_NUL}]"

#Now that that's done, let's load our modules
require_relative './modloader'
require_relative './root'

puts "This bot's invite URL is #{$bot.invite_url}."
puts 'Click on it to invite it to your server.'

#LETS RUN THIS SHIT
$bot.run


#  GLOBAL VARIABLES
## $bot [Discordrb::Commands::CommandBot]
##   Controls our connection to Discord, as well as handles commands
##
## $config [Hash]
##   Bot config, with stuff like the owner ID as well as where to load
##   modules and stored data from.
##
## $libconfig [Hash]
##   Configuration for $bot
##
## $modconfig [Hash]
##   Configuration for modules