module ArchivalUnit
	
	
	#####################
	###ARCHIVE#COMMAND###
	#####################
	command(:archive) do |event, msgcount = "250", withids = nil|
		break unless check_event(event)
		if !(check_admin(event))
			break if event.channel.id == 120330239996854274  #Newhome, check for admin
		end
		
		msgcount = msgcount.to_i
		if msgcount <= 0
			event.respond "Please enter a valid amount of messages to archive!"
			break
		end
		withids = withids ? true : false
		
		event.channel.start_typing
		
		filen = if msgcount <= 2000
							archive_memory(event, msgcount, withids)
						else
							if check_admin(event)
								archive_disk(event, msgcount, withids, 3)
							else
								event.respond "You shouldn't need to archive over 2000 messages.\nOn the off-chance that you do, contact a mod or admin!"
								nil
							end
						end
		return if filen.nil?
		
		#1024*1024*8 == 8388608
		#Round down to 8000000 for safety
		if File.size(filen) >= 8000000
			event << "Archive is 8MB or larger. Please ask the owner/maintainer of this bot, <@#{$config["ownerid"]}>, for the log."
			event << "This notice might disappear soon, if the owner ever gets off their lazy butt and implements Dropbox support."
		else
			event.channel.send_file(File.open(filen, "r"), caption: "Here's your archive.")
		end
	end
	
	
	def self.archive_memory(event, msgcount, withids)
		if msgcount < 0
			event.respond "I can't archive the future."
			return
		end
		
		archive_text = []
		archive_yield(event, msgcount) {|m_ary|
			m_ary.each {|m|
				archive_text << {:id => m.id, :msg => msg_to_string(m, nil, withids)}
			}
		}
		
		archive_text.sort! {|a,b|
			a[:id] <=> b[:id]
		}
		
		archive_text.map! {|m|
			m[:msg]
		}
		
		file = save_log(event, archive_text) # File name - String object
		
		file
	end
	
	def self.archive_disk(event, msgcount, withids, yields_before_dump = 1)
		file_num = 0
		json_filenames = []
		now_ts = (Time.now.utc - (60*60*5)).to_s << "-5"
		m_json_ary = []
		
		num_yields = 0
		archive_yield(event, msgcount) {|m_ary|
			m_json_ary += m_ary
			num_yields += 1
			
			if (num_yields >= yields_before_dump) || m_ary.length < 100
				m_json = JSON.generate(ary_to_hash(m_json_ary))
				fn = filename_check(File.join($config["tempdir"], "fa_#{now_ts}_#{file_num}"), ".json")
				fn.gsub!(/:/, "-")
				
				File.write(fn, m_json)
				json_filenames << fn
				
				file_num += 1
				num_yields = 0
				m_json_ary.clear
			end
		}
		
		log = json_files_to_log(event, json_filenames) {|m|
			id = withids ? "#{m[:id]} " : ""
			ts = id_to_time(m[:id]).strftime "%Y-%m-%d %H:%M"
			udist = begin
								event.bot.user(m[:uid]).distinct
							rescue
								"UserID #{m[:uid]}"
							end
			"#{id}#{ts} || #{udist} || #{m[:content]} #{m[:attach]}"
		}
		
		File.delete(*json_filenames)
		
		log
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
	
	command(:archsync) do |event|
		break unless event.user.id == $config["ownerid"]
		@channels.each {|c|
			chan = event.bot.channel(c)
			
			# Do this beforehand so we don't do so many resolve requests
			chan.server.members
			
			archive_yield(nil, 99999999999999, chan) {|m_ary|
				m_ary.each {|m|
					log_message(Discordrb::Events::MessageEvent.new(m, $bot), :create, m.timestamp, false)
				}
			}
			
			idstore_update(event.bot)
		}
		nil
	end
end