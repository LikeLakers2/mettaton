def eval_cmd(event, *code)
	return unless event.user.id == $config["ownerid"]
	
	begin
		att = event.message.attachments
		if !att.empty?
			fn = File.join($config["tempdir"], att[0].filename)
			File.binwrite(fn, RestClient.get(att[0].url).to_s)
			eval "eval_event = event; #{File.read(fn)}"
		else
			eval code.join(' ')
		end
	rescue => exc
		exc_msg = error_report(exc)
		if exc_msg.length >= 2000
			#We should send it as a file
			filename = File.join($config["tempdir"], "eval_exception.log")
			
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

def report(exc)
	exc_msg = error_report(exc)
	filename = File.join($config["tempdir"], "exception_#{Time.now.to_i}.log")
	
	File.write(filename, exc_msg, {:mode => 'w'})
	if exc_msg.length >= 2000
		#We should send it as a file
		f = File.open(filename, "r")
		msg_info = "Exception occured. (>2000 characters)"
		
		$bot.send_file(284389705972449291, f, caption: msg_info)
	else
		$bot.send_message(284389705972449291, exc_msg)
	end
rescue => exc_exc
	exc_msg = error_report(exc)
	filename = File.join($config["tempdir"], "exception_#{Time.now.to_i}-1.log")
	
	File.write(filename, exc_msg, {:mode => 'w'})
	puts "Error occured while reporting error. Exception log is located at ./temp/exception_#{Time.now.to_i}-1.log"
ensure
	puts "Error occured. Exception log is located at ./temp/exception_#{Time.now.to_i}.log"
end

def error_report(exc)
	e = exc.inspect
	e << "\n" << exc.backtrace.join("\n")
	
	exc_msg = []
	exc_msg << "```"
	e.gsub!(/`/, "'")
	e.gsub!(/\/home\/minecraft\/wikibot/i, "$BOT_HOME")
	e.gsub!(/\/opt\/rubies\/ruby-2\.3\.1\/lib\/ruby\/gems\/2\.3\.0\/gems/i, "$GEM_HOME")
	e.gsub!(/\$GEM_HOME\/discordrb-#{Discordrb::VERSION}\/lib\/discordrb/i, "$GEM-DRB")
	exc_msg << e
	exc_msg << "```"
	
	exc_msg = exc_msg.join("\n")
end

$bot.ready() do |event|
	event.bot.game = "Oh Yes Simulator"
end
