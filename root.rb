def eval_cmd(event, *code)
	return unless event.user.id == $config["ownerid"]
	
	begin
		att = event.message.attachments
		if !att.empty?
			fn = File.join($config["tempdir"], att[0].filename)
			File.binwrite(fn, RestClient.get(att[0].url).to_s)
			eval "eval_event = event; #{File.binread(fn)}"
		else
			eval code.join(' ')
		end
	rescue => exc
		e = exc.inspect
		e << "\n" << exc.backtrace.join("\n")
		
		exc_msg = []
		exc_msg << "```"
		e.gsub!(/`/, "'")
		e.gsub!(/\/home\/minecraft\/wikibot/i, "$BOT_HOME")
		e.gsub!(/\/opt\/rubies\/ruby-2\.3\.1\/lib\/ruby\/gems\/2\.3\.0\/gems/i, "$GEM_HOME")
		exc_msg << e
		exc_msg << "```"
		
		exc_msg = exc_msg.join("\n")
		if exc_msg.length >= 2000
			#We should send it as a file
			filename = File.join($config["tempdir"], "exception.log")
			
			File.write(filename, exc_msg, {:mode => 'w'})
			
			f = File.open(filename, "r")
			msg_info = "Exception occured. (>2000 characters)"
			event.send_file(f, caption: msg_info)
		else
			event << exc_msg
		end
	end
end

#Eval command will always be available even without modules loaded
$bot.command(:eval, help_available: false) do |event, *code|
	eval_cmd(event, code)
end

def check_event(event, need_admin = false)
	log_event(event)
	return true if event.user.id == $config["ownerid"]
	return false if need_admin and !check_admin(event)
	return false if check_ignored(event)
	return true
end

def log_event(event)
	servid = event.server.nil? ? "pm" : event.server.id
	puts "#{Time.now.to_i} CMD: (U#{event.user.id} S#{servid.to_s} C#{event.channel.id.to_s}) #{event.user.distinct} used '#{event.content}'"
end

def check_ignored(event)
	return true if $ignored_users.include? event.user.id
	return false
end

def check_admin(event)
	return true if event.user.id == $config["ownerid"]
	event.user.roles.each {|r|
		return true if $admin_roles.include? r.id
	}
	return false
end

$bot.ready() do |event|
	$bot.gateway.check_heartbeat_acks = true
	event.bot.game = "Oh Yes Simulator"
end