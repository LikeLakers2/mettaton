module HelpCommand
	extend Discordrb::Commands::CommandContainer
	
	command(:help) do |event, *command|
		break unless check_event(event)
		command = do_command(command)
		
		event.respond ":mailbox_with_mail: Please check your DMs! If you don't receive one, check your privacy settings and try again!" unless event.channel.private?
		if command.empty? or command == "help"
			helplist(event)
		else
			helpcmd = "help_#{do_alias(command)}.txt"
			do_help(event, helpcmd)
		end
		nil
	end
	
	def self.do_command(command)
		do_prefix(command.join(' ')).strip.gsub(' ', '_').downcase
		
		#p command                      ## [":mttoh:", "CM", "VIEW"]
		#p cmd = command.join(' ')      ## ":mttoh: CM VIEW"
		#p cmd = do_prefix(cmd)         ## " CM VIEW"
		#p cmd = cmd.strip              ## "CM VIEW"
		#p cmd = cmd.gsub(' ', '_')     ## "CM_VIEW"
		#p cmd = cmd.downcase           ## "cm_view"
		#cmd
		
		
		#do_prefix(command.join(' ')).gsub(' ', '_').downcase
		#do_prefix(command.join(' ')).split(' ').join('_').downcase
	end
	
	def self.do_prefix(command)
		$libconfig["prefix"].map { |e| do_prefix_internal(command, e) }.reduce { |m, e| m || e } || command
	end
	
	def self.do_prefix_internal(command, prefix)
		return nil unless command.start_with? prefix
		command[prefix.length..-1]
	end
	
	def self.do_alias(command)
		case command
		when /^cm/i then command.gsub(/^cm/i, 'charmanage')
		when /^(roll|dr)/i then command.gsub(/^(roll|dr)/i, 'diceroll')
		when /^\<?(rolecommand|rp-applicant|rp|npc)\>?/i then command.gsub(/^\<?(rolecommand|rp-applicant|rp|npc)\>?/i, 'rolecommand')
		else command
		end
	end
	
	def self.helplist(event)
		#adm = check_admin(event)
		do_help(event, "helplist-intro.txt")
		if check_admin(event)
			do_help(event, "helplist-commands_admin.txt")
		else
			do_help(event, "helplist-commands.txt")
		end
	end
	
	def self.do_help(event, command_file)
		filename = File.join($config["moduledir"], "help", command_file)
		begin
			f_text = File.read(filename)
			event.user.pm f_text
		rescue
			event.user.pm "No help for that command exists."
		end
	end
end