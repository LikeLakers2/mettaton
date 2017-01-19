module CharAppManager
	command([:approve, :pending, :deny]) do |event, charid, *reason|
		break unless check_event(event, true)
		set_status(event.command.name, event, charid)
	end
	
	command([:accept, :decline, :reject]) do |event, charid, *reason|
		break unless check_event(event, true)
		case event.command.name
		when :accept
			set_status(:approve, event, charid)
		when :decline, :reject
			set_status(:deny, event, charid)
		end
	end
	
	def self.set_status(action, event, charid)
		servid = event.server.id
		if charid.downcase == "l"
			if @characters[servid].last.nil?
				event.respond "Last character was deleted before this command was executed."
				return
			else
				charid = @characters[servid].last.properties["charid"]
			end
		else
			charid = get_charid(event, servid, charid)
			return if !charid
		end
		
		case action
		when :approve
			status = "Approved"
		when :pending
			status = "Pending"
		when :deny
			status = "Denied"
		end
		
		@characters[servid][charid].properties["Status"] = status
		event.respond "Property `Status` of character ID #{charid.to_s} changed to `#{status}`."
		save_char(servid, charid)
		
		charname = @characters[servid][charid]["Name"] || "N/A"
		statusmsg = "The status of character ID **#{charid.to_s}** (Name: **#{charname}**) has been changed to **#{status}** by **#{event.user.name}**."
		statusmsg << "\nIf you wish to resubmit your character, type `rp!reregister #{charid.to_s}` in #roleplay-ooc or #truelab." unless action == :approve
		
		reason = event.content.split(' ')[2..-1].join(' ')
		if !(reason.empty?)
			statusmsg << "\n\nThe reason given for this action is:\n#{reason}"
		end
		
		ownerid = @characters[servid][charid]["ownerid"]
		u = event.server.member(ownerid)
		unless u.nil?
			if u.role?(251776958650777600)
				to_add = event.server.role(250917798845349888)
				to_remove = event.server.role(251776958650777600)
				u.modify_roles(to_add, to_remove)
			end
			u.pm(statusmsg)
		end
	end
end
