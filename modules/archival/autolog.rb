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
	
	def self.log_message(event, type, override_time = nil)
		return unless @channels.include? event.channel.id
		
		id = msg_to_id(event)
		
		date = (override_time || Time.now).strftime '%Y-%m-%d'
		p file = log_fn("#{event.channel.id}_#{date}")
		if File.exist?(file)
			js = JSON.parse(File.read(file, {}))
			d = js.find{|m| m['id'] == id}
		else
			js = nil
			d = nil
		end
		
		nd = send("d_msg#{type}", event, d)
		return unless nd
		#p nd
		
		update_logs(file, js, id, nd)
		idstore_update(event.bot)
	end
	def self.find_fn_by_id(id, chanid)
		date = id_to_time(id).strftime '%Y-%m-%d'
		
		f = File.join($config["datadir"], "archivalunit", "fulllogs", "#{chanid}_#{date}") << ".json"
		if File.exist?(f)
			js = JSON.parse(File.read(f, { encoding: "UTF-8" }))
			#{
			#  "1":[1234, 1236],
			#  "2":[1237, 1239]
			#}
			js.each_pair {|k,v|
				return k if (v[0]..v[1]).include? id
			}
		end
	end
	def self.log_fn(name)
		base = File.join($config["datadir"], "archivalunit", "fulllogs")
		ext = ".json"
		fn = File.join(base, name) << "-0#{ext}"
		return fn unless (File.size?(fn) || 0) > (1024*1024*25)
		return fn
		got_name = false
		fn_id = 1
		until got_name
			fn = File.join(base, name) << "-#{fn_id}#{ext}"
			if (File.size?(fn) || 0) > (1024*1024*25)
				fn_id += 1
				next
			else
				got_name = true
			end
		end
		
		index_fn = File.join(base, name) << ext
		[index_fn, fn]
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