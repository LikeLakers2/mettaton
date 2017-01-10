Dir.glob("./patching/*.rb") { |mod|
	puts "Patching with ./#{mod}"
	require_relative "./#{mod}"
}

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
		#puts e
		
		#event << "An error occured :disappointed:"
		event << "```"
		event << e.gsub(/`/, "'")
		event << "```"
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
	puts "CommandUsage: #{event.user.distinct} (#{event.user.id}) (in #{servid.to_s}, #{event.channel.id.to_s}) used '#{event.content}'"
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
	event.bot.game = "Oh Yes Simulator"
end