module ArchivalUnit
	# Grabs all the messages we need and returns them in an array
	# Return format: [[100,1],[200,101],[250,201]]
	# 250 is earliest message, 1 is latest
	def self.grab_history(event, count)
		return [] if count <= 0
		
		history = []
		#Discord only replies with 100 messages at max for each history request
		fullgrabs = (count/100).floor
		extragrab = count % 100
		
		before_id = nil
		fullgrabs.times{|i|
			history << event.channel.history(100, before_id)
			
			if history.last.empty? or history.last.length < 100 #or before_id == history.last.last.id
				#Short-circuit if we notice that we aren't getting any more messages.
				extragrab = 0
				break
			else
				#Discord outputs latest messages first in the array
				before_id = history.last.last.id
				#So we don't spam the servers
				sleep 0.1
			end
		}
		
		history << event.channel.history(extragrab, before_id) unless extragrab == 0
		
		# [[100,1],[200,101],[250,201]].reverse
		# History array will be in a weird format so we need to reverse it
		#history.reverse!
		
		return history
	end
	
	# Changes the entire array from Message objects to String objects
	# Return format: [250, 201, 200, 101, 100, 1]
	# 250 is earliest message, 1 is latest
	def self.history_to_text(history, withids = false)
		text_ary = []
		
		history.each {|block|
			#[250,201]
			block.each {|msg|
				text_ary << msg_to_string(msg, "", withids)
			}
		}
		# [1, 100, 101, 200, 201, 250]
		text_ary.reverse!
		# [250, 201, 200, 101, 100, 1]
		return text_ary
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