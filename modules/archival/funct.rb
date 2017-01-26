module ArchivalUnit
	def self.ary_to_hash(msg_ary)
		msg_ary.map {|m| msg_to_hash(m)}
	end
	
	def self.msg_to_hash(msg_obj)
		{
			:id => msg_obj.id,
			:uid => msg_obj.author.id,
			:content => msg_obj.content,
			:attach => msg_obj.attachments.map {|attach| attach.url}.join(' ')
		}
	end
	
	def self.id_to_time(id)
		ms = (id >> 22) + Discordrb::DISCORD_EPOCH
		Time.at(ms / 1000.0)
	end
	
	def self.json_files_to_log(event, file_ary)
		log_ary = []
		file_ary.each {|f|
			log_ary += JSON.parse(File.read(f), symbolize_names: true)
		}
		
		log_ary.sort! {|a,b|
			a[:id] <=> b[:id]
		}
		
		log_ary.map! {|m| yield m }
		
		fn = save_log(event, log_ary)
		
		fn
	end
	
	
	# Takes the array of text and saves it to a log file, with some prepended text
	# Return format: "FILENAME OF FILE.log"
	def self.save_log(event, archive_array)
		time = (Time.now.utc - (60*60*5)).to_s << "-5"
		
		fparam = {}
		#fparam[:filename] = filename_check(File.join($config["datadir"], "archivalunit", "archives", "#{event.server.id}_#{event.channel.id}_#{time}"), ".log")
		fparam[:filename] = filename_check(File.join($config["datadir"], "archivalunit", "archives", "#{time}"), ".log")
		fparam[:filename].gsub!(/:/, "-")
		fparam[:introtext] = "Archival of channel \"#{event.channel.name}\" on server \"#{event.server.name}\"\n"
		fparam[:introtext] << "Number of messages archived: #{archive_array.length}\n"
		fparam[:introtext] << "Date of archive creation: #{time}\n"
		fparam[:introtext] << "-" * 75 << "\n\n"
		
		f = File.open(fparam[:filename], "w+")
		
		f.write(fparam[:introtext])
		f.write(archive_array.join("\n"))
		f.write("\n")

		f.close
		
		fparam[:filename]
	end
	
	
	def self.filename_check(filename, ext)
		return "#{filename}#{ext}" unless File.file? "#{filename}#{ext}"
		
		got_name = false
		append_num = 1
		
		until got_name
			filename_result = "#{filename}-#{append_num}#{ext}"
			if File.file? filename_result
				append_num += 1
			else
				got_name = true
			end
		end
		
		filename_result
	end
end