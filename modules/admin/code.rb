module BotAdmin
	extend Discordrb::Commands::CommandContainer
	
	command(:config) do |event, action|
		break unless event.user.id == $config["ownerid"]
		
		case action.downcase
		when "reload"
			puts "Reloading configurations..."
			global_reload_config
			
			$mods.each {|i|
				next unless i.respond_to? :reload_config
				begin
					i.reload_config
					puts "Config reloaded for #{i.to_s}"
				rescue
					puts "Failed to reload config for #{i.to_s}"
				end
			}
		when "save"
			puts "Saving configurations..."
			$mods.each {|i|
				next unless i.respond_to? :save_config
				begin
					i.save_config
					puts "Config saved for #{i.to_s}"
				rescue
					puts "Failed to save config for #{i.to_s}"
				end
			}
			
			global_save_config
		end
		nil
	end
	
	command(:roles) do |event|
		break unless event.user.id == $config["ownerid"]
		roles = event.server.roles
		
		event << "Roles for #{event.server.name}:"
		event << ""
		event << "(ID) | (ROLE NAME) | (PERMISSION BITS)"
		event << "```"
		roles.sort{ |a,b|
			b.position <=> a.position #Reverse order so @everyone is last
		}.each { |r|
			event << "#{r.id} | #{r.name} | #{r.permissions.bits}"
		}
		event << "```"
	end
	
	command(:permissions) do |event, id = nil|
		break unless event.user.id == $config["ownerid"]
		id ||= event.author.id
		id = id.to_i
		thing = event.server.role(id) || event.server.member(id)
		if thing
			flags = Discordrb::Permissions::Flags
			if thing.is_a?(Discordrb::Role)
				perms = flags.values.map{|v|
					thing.permissions.instance_variable_get("@#{v}")
				}
			elsif thing.is_a?(Discordrb::Member)
				perms = flags.values.map {|v|
					thing.permission?(v)
				}
			end
			
			event << "Permissions for #{thing.name} in #{event.server.name}:"
			event << "```"
			Discordrb::Permissions::Flags.each_value.with_index { |name,idx|
				event << "	#{name}: #{perms[idx]}"
			}
			event << "```"
		else
			event << "Could not find a role or member with that ID."
		end
	end
	
	command(:ignore, help_available: false) do |event, mod = "", *users|
		break unless check_event(event, true)
		case mod.downcase
		when "+", "add"
			event.message.mentions.each {|u|
				if $ignored_users.include? u.id
					event << "User **#{u.distinct}** has already been ignored!"
				else
					$ignored_users << u.id
					event << "User **#{u.distinct}** has been ignored."
				end
			}
			File.write('./ignored_users.txt', $ignored_users.join("\n"))
		when "-", "remove"
			event.message.mentions.each {|u|
				if $ignored_users.include? u.id
					$ignored_users.delete u.id
					event << "User **#{u.distinct}** has been unignored."
				else
					event << "User **#{u.distinct}** is not already ignored!"
				end
			}
			File.write('./ignored_users.txt', $ignored_users.join("\n"))
		when "?", "list"
			ig = $ignored_users
			if ig.empty?
				event << "No users are currently being ignored."
			else
				event << "List of `#{ig.count}` ignored users:"
				num = 1
				ig.each {|uid|
					u = event.bot.users[uid.to_i]
					if u.nil?
						event << "`#{num}.` ID **#{uid}** (Bot does not share a server)"
					else
						event << "`#{num}.` **#{u.distinct}** (ID #{uid})"
					end
					num += 1
				}
			end
		end
		nil
	end
	
	command(:joinserver, help_available: false) do |event|
		break unless event.user.id == $config["ownerid"]
	
		event.user.send $bot.invite_url
		nil
	end
	
	command(:exit, help_available: false) do |event|
		break unless event.user.id == $config["ownerid"]
		event.respond "Exiting..."
		$bot.stop
		nil
	end
end