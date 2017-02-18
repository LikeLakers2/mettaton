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
		log_message(event,"create")
	end
	message_edit() do |event|
		log_message(event,"edit")
	end
	message_delete() do |event|
		log_message(event,"delete")
	end
	
	def self.log_message(event, type)
		return unless @channels.include? event.channel.id
		
		date = Time.now.strftime "%Y-%m-%d"
		file = File.join($config["datadir"], "archivalunit", "fulllogs", "#{event.channel.id}_#{date}") << ".json"
		d = if File.exist?(file)
					JSON.parse(File.read(file)).select{|m| m['id'] == event.message.id}.first
				else
					nil
				end
		send("d_msg#{type}", event, d)
	end
	
	def self.d_msgcreate(event, d = nil)
		update_logs(event, id, d_msgdefault(event))
	end
	def self.d_msgedit(event, d)
		d['hist'] << msgev_to_json(event)
	end
	def self.d_msgdelete(event, d)
		d['delat'] = event.timestamp.to_i
	end
	
	def self.update_logs(event,id,hash)
		filename = File.join($config["datadir"], "archivalunit", "fulllogs", "#{event.channel.id}_#{date}") << ".log"
	end
	
	
	
	def self.d_msgdefault(event)
		{
			'id'=>event.message.id,
			'uid'=>event.user.id,
			'mo'=>msgev_to_json(event),
			'hist'=>[],
			'delat'=>nil
		}
	end
	def self.msgev_to_hash(event)
		{
			'ts'=>event.timestamp.to_i,
			'content'=>event.content,
			'attach'=>attach_to_ary(event)
		}
	end
	def self.attach_to_url(event)
		event.message.attachments.map {|attach| attach.url}
	end
	
	#def self.old_def_json(event)
	#	{
	#		"t"=>[0,1,2],
	#		"mid"=>event.message.id,
	#		"ts"=>event.timestamp.to_i,
	#		"uid"=>event.user.id,
	#		"content"=>event.content,
	#		"attach"=>attach_to_ary(event),
	#		"editat"=>nil,
	#		"delat"=>nil
	#	}
	#end
	
end