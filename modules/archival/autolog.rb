module ArchivalUnit
	#####################
	######VARIABLES######
	#####################
	
	# @return [Array<Integer>] List of channel IDs we want to archive.
	attr_accessor :channels
	
	
	#####################
	#######EVENTS########
	#####################
	
	message() do |event|
		log_message(event, "#{event.message.id} ")
	end
	
	message_edit() do |event|
		log_message(event, "#{event.message.id}-edit ")
	end
	
	message_delete() do |event|
		if @channels.include? event.channel.id
			date = (Time.now.utc - (60*60*5)).strftime "%Y-%m-%d"
			filename = File.join($config["datadir"], "archivalunit", "fulllogs", "#{event.channel.id}_#{date}") << ".log"
			
			File.write(filename, "\n#{event.id}-delete", {:mode => 'a'})
		end
	end
	
	def self.log_message(event, prepend = nil)
		return unless @channels.include? event.channel.id
		
		date = (Time.now.utc - (60*60*5)).strftime "%Y-%m-%d"
		filename = File.join($config["datadir"], "archivalunit", "fulllogs", "#{event.channel.id}_#{date}") << ".log"
		
		File.write(filename, "\n"+msg_to_string(event.message, prepend), {:mode => 'a'})
	end
	
end