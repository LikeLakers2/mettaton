module ArchivalUnit
	command(:archivejsontest) do |event, msgcount = "250"|
		break unless event.user.id == $config["ownerid"]
		msgcount = msgcount.to_i
		fns = archive_json_test(event, msgcount)
		fns2 = [
			"./temp/fa_2017-01-26 13-29-23 UTC-5_0.json",
			"./temp/fa_2017-01-26 13-29-23 UTC-5_1.json",
			"./temp/fa_2017-01-26 13-29-23 UTC-5_2.json",
			"./temp/fa_2017-01-26 13-29-23 UTC-5_3.json",
			"./temp/fa_2017-01-26 13-29-23 UTC-5_4.json",
			"./temp/fa_2017-01-26 13-29-23 UTC-5_5.json",
			"./temp/fa_2017-01-26 13-29-23 UTC-5_6.json",
			"./temp/fa_2017-01-26 13-29-23 UTC-5_7.json",
			"./temp/fa_2017-01-26 13-29-23 UTC-5_8.json",
			"./temp/fa_2017-01-26 13-29-23 UTC-5_9.json"
		]
		log = json_files_to_log(fns) {|m|
			ts = id_to_time(m[:id]).strftime "%Y-%m-%d %H:%M"
			udist = begin
								event.bot.user(m[:uid]).distinct
							rescue
								"UserID #{m[:uid]}"
							end
			"#{m[:id]} #{ts} || #{udist} || #{m[:content]} #{m[:attach]}"
		}
		GC.start
		'done'
	end
	
	def self.archive_json_test(event, count)
		return [] if count <= 0
		event.channel.start_typing
		now_ts = (Time.now.utc - (60*60*5)).to_s << "-5"
		start_ts = Time.now.to_f
		
		q_grab_to_json = Queue.new
		# @return Array<String> The filenames of the archives files to be sent
		ary_filenames = []
		
		t = {}
		t[:grab_history] = Thread.new {
			before_id = nil
			got_count = 0
			while true
				history = get_history(count, got_count, event.channel, before_id)
				q_grab_to_json << history
				if history.length < 100
					#We've reached the beginning of the channel, celebrate
					q_grab_to_json.close
					break
				end
				before_id = history.last.id
				got_count += history.length
				#sleep 0.5
				sleep 1
			end
		}
		
		t[:history_to_json_file] = Thread.new {
			file_num = 0
			while m_ary = q_grab_to_json.pop
				m_json = JSON.generate(ary_to_json(m_ary))
				
				fn = filename_check(File.join($config["tempdir"], "fa_#{now_ts}_#{file_num}"), ".json")
				fn.gsub!(/:/, "-")
				
				File.write(fn, m_json)
				ary_filenames << fn
				
				file_num += 1
			end
		}
		
		t.each_pair {|n,t| p t.value}
		
		#ary_filenames.each {|name|
		#	event.send_file(File.open(name))
		#	sleep 1
		#}
		ary_filenames
		#nil
	end
	
	def self.json_files_to_log(file_ary)
		log_ary = []
		file_ary.each {|f|
			log_ary += JSON.parse(File.read(f), symbolize_names: true)
		}
		
		log_ary.sort! {|a,b|
			a[:id] <=> b[:id]
		}
		
		fn = "./temp/output.log"
		log_ary.map! {|m| yield m }
		File.write(fn, log_ary.join("\n"))
		[log_ary.first, log_ary.last]
	end
	
	
	def self.ary_to_json(msg_ary)
		msg_ary.map {|m| msg_to_json(m)}
	end
	
	def self.msg_to_json(msg_obj)
		{
			:id => msg_obj.id,
			:uid => msg_obj.author.id,
			:content => msg_obj.content,
			:attach => msg_obj.attachments.map {|attach| attach.url}.join(' ')
		}
		#"#{msgid}#{prepend}#{ts} || #{user} || #{msg}"
	end
	
	def self.id_to_time(id)
		ms = (id >> 22) + Discordrb::DISCORD_EPOCH
		Time.at(ms / 1000.0)
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
end