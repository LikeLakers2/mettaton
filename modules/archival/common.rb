module ArchivalUnit
	extend Discordrb::Commands::CommandContainer
	extend Discordrb::EventContainer
	
	
	#####################
	#######EVENTS########
	#####################
	
	ready() do |event|
		reload_config
	end
	
	
	def self.archive_yield(event, count)
		return if count <= 0
		event.channel.start_typing
		
		wait_time = get_wait_time(count)
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
				
				sleep wait_time
			end
		}
		
		t[:history_yield] = Thread.new {
			while m_ary = q_grab_to_history.pop
				yield m_ary
			end
		}
		
		#t.each_pair {|n,t| p t.value}
		t.each_value {|t| t.join}
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
	
	
	# Format of strings: "2016-11-30 11:24:18 UTC || MichiRecRoom#9507 || hello im a message http://attachment.com/attachment.txt"
	def self.msg_to_string(msg_obj, prepend = nil, withid = false)
		ts = (msg_obj.timestamp.utc - (60*60*5)).strftime "%Y-%m-%d %H:%M"        # 2016-11-30 11:24:18 UTC
		user = begin
						 msg_obj.author.distinct
					 rescue
						 "UserID #{m[:uid]}"
					 end
		
		msg = msg_obj.content
		msg << " " << msg_obj.attachments.map {|attach| attach.url}.join(' ') unless msg_obj.attachments.empty?
		# #{content} #{attach1} #{attach2}
		
		msgid = withid ? "#{msg_obj.id} " : ""
		prepend = prepend.nil? ? "" : prepend
		"#{msgid}#{prepend}#{ts} || #{user} || #{msg}"
	end
	
	
	#####################
	###CONFIG##METHODS###
	#####################
	def self.reload_config
		f_array = File.readlines(File.join($config["datadir"], "archivalunit", "logchannels.txt"))
		@channels = ary_str2int(f_array)
	end
	
end