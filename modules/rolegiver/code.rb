module RoleGiver
	extend Discordrb::Commands::CommandContainer
	extend Discordrb::EventContainer
	
	
	#####################
	#######EVENTS########
	#####################
	
	ready() do |event|
		reload_config
	end
	
	
	#####################
	######VARIABLES######
	#####################
	
	# @return [Array<Hash>] List of commands, and their configs
	#   {:command => <CommandObj>, :cmdcfg => {"cmdname"=>"hello", "giverole"=>254623987122962432, "takeroles"=>[254624059277574144, 254624091468857344]}}
	attr_accessor :customcmds
	
	
	def self.role_give(event)
		begin
			unless event.server.member($bot.profile.id).permission? :manage_roles
				event.respond "I can't seem to do that -- I don't have the **Manage Roles** permission!"
				return
			end
			
			event.channel.start_typing   #There seems to be a bit of lag with doing these commands, so...
			cfg = get_giver_cfg(event.command.name)[:cmdcfg]
			
			to_add = event.server.role(cfg["giverole"])
			to_remove = event.server.roles.select {|role| cfg["takeroles"].include? role.id}
			
			msg = ""
			event.message.mentions.each {|user|
				user.on(event.server.id).modify_roles(to_add, to_remove)
				msg << "User **#{user.distinct}** has been given that role."
			}
			# Apparently this doesn't send the message unless we do event.respond ???
			event.respond msg unless msg.empty?
		rescue => exc
			event.respond "Something went wrong! Most likely my roles are not high enough in the role hierarchy to manage the roles needed."
			puts exc.inspect
			puts exc.backtrace.join("\n")
		end
	end
	
	def self.get_giver_cfg(name)
		@customcmds.find {|i| i[:cmdcfg]["cmdname"] == name.to_s }
	end
	
	#####################
	####ROLE##COMMANDS###
	#####################
	command(:giveme) do |event|
		begin
			break unless event.server.id == 120330239996854274   #/r/UT
			#break unless event.server.id == 256789342687592448   #MTT
			break unless check_event(event)
			
			unless event.server.member($bot.profile.id).permission? :manage_roles
				event.respond "I can't seem to do that -- I don't have the **Manage Roles** permission!"
				return
			end
			
			if event.user.role?(251795395863117834)   #NPC
				"Sorry, I can't give you the **RP-Applicant** role because you have the **NPC** role.\nIf you wish to roleplay again, please send an appeal to one of the GMs."
			elsif event.user.role?(250917798845349888)   #Roleplayer
				"You appear to already have the **Roleplayer** role! If for some reason, you cannot see any channels beginning with \"#roleplay-\", please notify a GM and we'll attempt to sort it out ASAP."
			elsif event.user.role?(251776958650777600)   #RP-Applicant
				"You've already been given the **RP-Applicant** role. Head over to <#251776534812033026>, read the rules, and register a character to get started."
			else
				event.user.add_role(251776958650777600)
				"I have given you the **RP-Applicant** role. Head over to <#251776534812033026>, read the rules, and register a character to get started."
			end
		rescue => exc
			event.respond "Something went wrong! Most likely my roles are not high enough in the role hierarchy to manage the roles needed."
			puts exc.inspect
			puts exc.backtrace.join("\n")
		end
	end
	
	
	#####################
	###CONFIG##METHODS###
	#####################
	def self.reload_config
		@customcmds ||= []
		@cmdcfg ||= []
		
		@customcmds.each {|c|
			$bot.remove_command c[:command].name
		}
		
		@customcmds = []
		cmdcfg = $modconfig["rolegiver"]["commands"]
		
		cmdcfg.each {|c|
			command_to_add = 	$bot.command(c["cmdname"].to_sym) do |event, *users|
													break unless check_event(event, true)
													role_give(event)
													nil
												end
			@customcmds << {:command => command_to_add, :cmdcfg => c}
		}
		
	end
end