module ArchivalUnit
	extend Discordrb::Commands::CommandContainer
	extend Discordrb::EventContainer
	
	
	#####################
	#######EVENTS########
	#####################
	
	ready() do |event|
		reload_config
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
		@channels = array_strng_to_int(f_array)
	end
	
end