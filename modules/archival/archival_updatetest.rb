module ArchivalUnit
	command(:archivenewtest) do |event|
		break unless event.user.id == $config["ownerid"]
		event.channel.start_typing
		now_ts = (Time.now.utc - (60*60*5)).to_s << "-5"
		start_ts = Time.now.to_f
		
		# @return Queue<Message> The messages that have been grabbed
		q_grab_to_text = Queue.new
		# @return Hash[String => Array<Message>] Message objects converted to Strings
		q_text_to_save = {}
		# @return Queue<String> The list of dates that are done being archived
		q_htt_done = Queue.new
		# @return Array<String> The filenames of the archives files to be sent
		ary_filenames = []
		
		t = {}
		t[:grab_history] = Thread.new {
			before_id = nil
			while true
				history = event.channel.history(100, before_id)
				history.each {|m|
					q_grab_to_text << m
				}
				if history.length < 100
					#We've reached the beginning of the channel, celebrate
					q_grab_to_text.close
					break
				end
				before_id = history.last.id
				sleep 1
			end
		}
		
		t[:history_to_text] = Thread.new {
			last_date = nil
			while m = q_grab_to_text.pop
				ts = (m.timestamp-(60*60*5)).strftime "%Y-%m-%d"
				q_text_to_save[ts] ||= []
				q_text_to_save[ts] << msg_to_string(m, nil, true)
				
				if !(last_date.nil?) && last_date != ts
					q_htt_done << last_date
				end
				last_date = ts
			end
			q_htt_done.close
		}
		
		t[:save_log] = Thread.new {
			while mts = q_htt_done.pop
				fn = filename_check(File.join($config["datadir"], "archivalunit", "archives", "fa_#{now_ts}_#{mts}"), ".log")
				fn.gsub!(/:/, "-")
				File.write(fn, q_text_to_save[mts].reverse.join("\n"))
				
				q_text_to_save.delete mts
				ary_filenames << fn
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
	
	
	def self.msg_to_string(msg_obj, prepend = nil, withid = false)
		ts = (msg_obj.timestamp.utc - (60*60*5)).strftime "%Y-%m-%d %H:%M"        # 2016-11-30 11:24:18 UTC
		user = "#{msg_obj.author.distinct}" # MichiRecRoom#9507
		
		msg = msg_obj.content
		msg << " " << msg_obj.attachments.map {|attach| attach.url}.join(' ') unless msg_obj.attachments.empty?
		# #{content} #{attach1} #{attach2}
		
		msgid = withid ? "#{msg_obj.id.to_s} " : ""
		prepend = prepend.nil? ? "" : prepend
		"#{msgid}#{prepend}#{ts} || #{user} || #{msg}"
	end
end