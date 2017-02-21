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
		log_message(event, :create)
	end
	message_edit() do |event|
		log_message(event, :edit)
	end
	message_delete() do |event|
		log_message(event, :delete)
	end
	
	def self.log_message(event, type)
		return unless @channels.include? event.channel.id
		
		id = msg_to_id(event)
		
		date = Time.now.strftime '%Y-%m-%d'
		file = File.join($config["datadir"], "archivalunit", "fulllogs", "#{event.channel.id}_#{date}") << ".json"
		if File.exist?(file)
			js = JSON.parse(File.read(file))
			d = js.find{|m| m['id'] == id}
		else
			js = nil
			d = nil
		end
		
		nd = send("d_msg#{type}", event, d)
		return unless nd
		p nd
		
		update_logs(file, js, id, nd)
	end
	
	def self.d_msgcreate(event, _)
		d_msgdefault(event)
	end
	def self.d_msgedit(event, data)
		return unless data
		new_msg = msgev_to_hash(event, {'ts'=>event.message.edit_timestamp.to_i})
		new_msg.delete('attach') if new_msg['attach'] == data['mo']['attach']
		(data['hist'] ||= []) << new_msg
		data
	end
	def self.d_msgdelete(event, data)
		return unless data
		data['delat'] = Time.now.to_i
		data
	end
	
	def self.update_logs(filename, d_json, msgid, msg)
		return unless msg
		d_json ||= []
		idx = d_json.find_index {|m| m['id'] == msgid } || d_json.length
		
		d_json[idx] = msg
		
		File.write(filename, JSON.generate(d_json), {:mode => 'w'})
	end
	
	
	def self.msg_to_id(event)
		if event.class == Discordrb::Events::MessageDeleteEvent
			event.id
		else
			event.message.id
		end
	end
	
	def self.d_msgdefault(event, custom = {})
		# custom is used in case we want to overwrite some field on this with a non-default
		{
			'id'=>event.message.id,
			'uid'=>event.user.id,
			'mo'=>msgev_to_hash(event)
		}.merge(custom)
	end
	def self.msgev_to_hash(event, custom = {})
		{
			'ts'=>event.timestamp.to_i,
			'content'=>event.content,
			'attach'=>attach_to_url(event)
		}.merge(custom)
	end
	#def self.msg_parse(message)
	#	nmsg = message.content.clone
	#	message.mentions.each {|u|
	#		nmsg.gsub!(/<@!?#{u.id}>/, "@#{u.distinct}")
	#	}
	#	message.
	#end
	def self.attach_to_url(event)
		event.message.attachments.map {|attach| attach.url}
	end
end