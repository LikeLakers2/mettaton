module ArchivalUnit
	
	
	#####################
	###ARCHIVE#COMMAND###
	#####################
	command(:archive) do |event, msgcount = 250, all_confirm = nil|
		break unless check_event(event)
		if !(check_admin(event))
			break if event.channel.id == 120330239996854274  #Newhome, check for admin
			break if msgcount.to_i >= 2500
		end
		
		all_messages = false
		withids = false
		
		if msgcount.to_s.downcase == "all"
			if check_admin(event)
				if all_confirm == "confirm"
					all_messages = true
				elsif all_confirm == "withids"
					all_messages = true
					withids = true
				else
					event << "All messages? That might take a while."
					event << "Use `rp!archive all confirm` (case-sensitive) to make sure you wanna do this."
					event << "You can also use `rp!archive all withids` to have me archive the message IDs too."
					break
				end
			else
				event << "You don't have permission to do that."
				break
			end
		else
			msgcount = msgcount.to_i
			if msgcount == 0
				#Upload empty file in response
				break
			elsif msgcount < 0
				event.respond "I can't archive the future."
				break
			end
		end
		
		event.channel.start_typing
		
		if all_messages
			history = grab_history_all(event)
		else
			history = grab_history(event, msgcount)  # [[250,201],[200,101],[100,1]] - Message objects
		end
		history_text = history_to_text(history, withids)  # [250, 201, 200, 101, 100, 1] - String objects
		file = save_log(event, history_text) # File name - String object
		
		#1024*1024*8 == 8388608
		#Round down to 8000000 for safety
		if File.size(file) >= 8000000
			event << "Archive is 8MB or larger. Please ask the owner/maintainer of this bot, <@#{$config["ownerid"]}>, for the log."
			event << "This notice might disappear soon, if the owner ever gets off their lazy butt and implements Dropbox support."
		else
			event.channel.send_file(File.open(file, "r"), caption: "Here's your archive.")
		end
	end
	
	
	
	def self.grab_history_all(event)
		history = []
		before_id = nil
		while true
			#Discord only replies with 100 messages at max for each history request
			history << event.channel.history(100, before_id)
			
			if history.last.empty? or history.last.length < 100 #or before_id == history.last.last.id
				#Short-circuit if we notice that we aren't getting any more messages.
				break
			else
				#Discord outputs latest messages first in the array
				before_id = history.last.last.id
				#So we don't spam the servers
				sleep 1
			end
		end
		history
	end
	
	
	#####################
	##HELPER#FUNCTIONS###
	#####################
	command(:archivechan) do |event, *args|
		break unless check_event(event, true)
		
		case args[0]
		when "+", "add"
			unless @channels.include? event.channel.id
				@channels << event.channel.id
				event << "Channel #{event.channel.name} added to auto-logging list."
			else
				event <<"Channel #{event.channel.name} is already being auto-logged."
			end
			File.write(File.join($config["datadir"], "archivalunit", "logchannels.txt"), @channels.join("\n"))
		when "-", "remove"
			if @channels.include? event.channel.id
				@channels.delete event.channel.id
				event << "Channel #{event.channel.name} removed from auto-logging list."
			else
				event << "Channel #{event.channel.name} does not exist in the auto-logging list."
			end
			File.write(File.join($config["datadir"], "archivalunit", "logchannels.txt"), @channels.join("\n"))
		when "?", "list"
			event << "List of channel IDs on auto-logging list:"
			event << @channels.to_s
		end
		nil
	end
	
	
end