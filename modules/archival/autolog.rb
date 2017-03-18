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
	
	def self.log_message(event, type, override_time = nil, update_idstore = true)
		return unless @channels.include? event.channel.id
		
		id = msg_to_id(event)
		
		date = (override_time || Time.now).strftime '%Y-%m-%d'
		file = log_fn("#{event.channel.id}_#{date}")
		if File.exist?(file)
			js = JSON.parse(File.read(file, { encoding: "UTF-8" }))
			d = js.find{|m| m['id'] == id}
		else
			js = nil
			d = nil
		end
		
		nd = send("d_msg#{type}", event, d)
		return unless nd
		#p nd
		
		update_logs(file, js, id, nd)
		idstore_update(event.bot) if update_idstore
	rescue => exc
		report(exc)
		
		error_msg = []
		error_msg << "Error while logging message."
		error_msg << "Server ID: #{(event.server.id||0).resolve_id || 'Unknown'}"
		error_msg << "Channel ID: #{(event.channel||0).resolve_id || 'Unknown'}"
		error_msg << "Message ID: #{(event.message||0).resolve_id || 'Unknown'}"
		error_msg = error_msg.join("\n")
		$bot.send_message(284389705972449291, error_msg)
	end
	def self.log_fn(name)
		base = File.join($config["datadir"], "archivalunit", "fulllogs")
		ext = ".json"
		fn = File.join(base, name) << "-0#{ext}"
		fn
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
		d_json ||= []
		idx = d_json.find_index {|m| m['id'] == msgid } || d_json.length
		
		d_json[idx] = msg
		
		File.write(filename, JSON.generate(d_json), {:mode => 'w'})
	end
	
	
	def self.msg_to_id(event)
		event.class == Discordrb::Events::MessageDeleteEvent ? event.id : event.message.id
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
	def self.attach_to_url(event)
		event.message.attachments.map {|attach| attach.url}
	end
end