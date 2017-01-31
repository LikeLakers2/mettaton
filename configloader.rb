
###                                                                    ###
#  Configuration loader for the bot. Loads the config into three vars.   #
#     $config   - Contains stuff such as ownerid, and what dirs to load  #
#                 other stuff from.                                      #
#  $libconfig   - Configuration for the bot instance.                    #
#  $modconfig   - Configuration for modules.                             #
###                                                                    ###

require 'json'

def ary_str2int(array)
	array.map {|item| item.to_i }
end

def global_reload_config
	$config, $libconfig, $modconfig, $ignored_users, $admin_roles, $credentials = [{},{},{},[],[],{}]
	#$config ||= {}
	#$libconfig ||= {}
	#$modconfig ||= {}
	#$ignored_users ||= []
	#$admin_roles ||= []
	#$credentials ||= {}
	
	puts "Loading config.json..."
	
	f = File.open("config.json").read
	j = JSON.parse(f)
	
	$config = j["botconfig"]
	$libconfig = j["libconfig"]
	$modconfig = j["modconfig"]
	
	puts "Loading ignored_users.txt"
	$ignored_users = ary_str2int(File.readlines("ignored_users.txt"))
	
	puts "Loading admin_roles.txt"
	$admin_roles = ary_str2int(File.readlines("admin_roles.txt"))
	
	#Put this last just to be absolutely sure.
	$credentials = JSON.parse(File.open("creds.json").read)
	
	puts "Loading config successful."
end

def global_save_config
	puts "Saving configuration to config.json"
	
	f = File.open("config.json", "w+")
	j = {"botconfig"=>$config, "libconfig"=>$libconfig, "modconfig"=>$modconfig}
	j_gen = JSON.pretty_generate(j)
	
	f.write(j_gen)
	f.close
	
	puts "Saving config successful."
end

global_reload_config