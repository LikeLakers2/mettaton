module ArchivalUnit
	
	
	#####################
	###ARCHIVE#COMMAND###
	#####################
	command(:archive) do |event, msgcount = "250", withids = nil|
		break unless check_event(event)
		if !(check_admin(event))
			break if event.channel.id == 120330239996854274  #Newhome, check for admin
		end
		break unless event.user.id == $config["ownerid"]
		
		event.channel.start_typing
		
		msgcount = msgcount.to_i
		withids = false
		withids = true if withids
		
		
		filen = if msgcount <= 2000
							archive_memory(event, msgcount, withids)
						else
							archive_disk(event, msgcount, withids)
						end
		
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
	
	def self.archive_disk(event, msgcount, withids)
		file_num = 0
		ary_filenames = []
		now_ts = (Time.now.utc - (60*60*5)).to_s << "-5"
		
		archive_yield(event, msgcount) {|m_ary|
			m_json = JSON.generate(ary_to_hash(m_ary))
			
			fn = filename_check(File.join($config["tempdir"], "fa_#{now_ts}_#{file_num}"), ".json")
			fn.gsub!(/:/, "-")
			
			File.write(fn, m_json)
			ary_filenames << fn
			
			file_num += 1
		}
		
		log = json_files_to_log(ary_filenames) {|m|
			id = withids ? "#{m[:id]} " : ""
			ts = id_to_time(m[:id]).strftime "%Y-%m-%d %H:%M"
			udist = begin
								event.bot.user(m[:uid]).distinct
							rescue
								"UserID #{m[:uid]}"
							end
			"#{id}#{ts} || #{udist} || #{m[:content]} #{m[:attach]}"
		}
		
		log
	end
	
	
	
	
	
	
	def self.archive_yield(event, count)
		return if count <= 0
		event.channel.start_typing
		
		q_grab_to_history = Queue.new
		
		t = {}
		t[:grab_history] = Thread.new {
			before_id = nil
			got_count = 0
			while true
				history = get_history(count, got_count, event.channel, before_id)
				q_grab_to_history << history
				if history.length < 100
					#We've reached the beginning of the channel, celebrate
					q_grab_to_history.close
					break
				end
				before_id = history.last.id
				got_count += history.length
				#sleep 0.5
				sleep 1
			end
		}
		
		t[:history_yield] = Thread.new {
			while m_ary = q_grab_to_history.pop
				yield m_ary
			end
		}
		
		t.each_pair {|n,t| p t.value}
		
	end
	
	def self.json_files_to_log(file_ary)
		log_ary = []
		file_ary.each {|f|
			log_ary += JSON.parse(File.read(f), symbolize_names: true)
		}
		
		log_ary.sort! {|a,b|
			a[:id] <=> b[:id]
		}
		
		fn = "./temp/output.log"
		log_ary.map! {|m| yield m }
		File.write(fn, log_ary.join("\n"))
		fn
	end
	
	
	def self.ary_to_hash(msg_ary)
		msg_ary.map {|m| msg_to_hash(m)}
	end
	
	def self.msg_to_hash(msg_obj)
		{
			:id => msg_obj.id,
			:uid => msg_obj.author.id,
			:content => msg_obj.content,
			:attach => msg_obj.attachments.map {|attach| attach.url}.join(' ')
		}
		#"#{msgid}#{prepend}#{ts} || #{user} || #{msg}"
	end
	
	def self.id_to_time(id)
		ms = (id >> 22) + Discordrb::DISCORD_EPOCH
		Time.at(ms / 1000.0)
	end
	
	def self.get_history(count, got_count, channel, before_id)
		to_get = count - got_count
		if to_get < 100
			case to_get
			when 0 # Get nothing
				[]
			when 1 # Get 1
				[channel.history(2, before_id).first]
			else # Get less than 100 but more than 1
				channel.history(to_get, before_id)
			end
		else # Get 100
			channel.history(100, before_id)
		end
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