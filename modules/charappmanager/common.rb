module CharAppManager
	extend Discordrb::Commands::CommandContainer
	extend Discordrb::EventContainer
	
	
	#####################
	######VARIABLES######
	#####################
	
	# @return [Hash[Integer => Array<PageWithProperties>]]
	# {SERVERID => WIKI}
	attr_accessor :characters
	
	
	#####################
	#######EVENTS########
	#####################
	
	ready() do |event|
		reload_config
	end
	
	server_create() do |event|
		#@characters[event.server.id] ||= Wiki.new
		@characters[event.server.id] ||= []
	end
	
	command(:ceval) do |event, *code|
		eval_cmd(event, code)
	end
	
	#####################
	###HELPER##METHODS###
	#####################
	def self.url_block(string)
		url_regex = /(https?:\/\/[^\s]+)/i
		string.gsub(url_regex, '<\1>').squeeze("<>")
	end
	
	#####################
	###CONFIG##METHODS###
	#####################
	def self.reload_config
		@regstate ||= {}
		@characters ||= {}
		
		##### @CHARACTERS #####
		
		chardir = File.join($config["datadir"], "charappmanager", "characters")
		Dir.entries(chardir).each {|servdir|
			next if servdir == '.' or servdir == '..'
			servid = servdir.to_i
			servdir = File.join(chardir, servdir)
			puts "CharAppManager: Loading characters for server ID #{servid}"
			
			#@characters[servid] = Wiki.new
			@characters[servid] = []
			app_load_ary = []
			Dir.glob(File.join(servdir, "char_*.json")) {|app|
				js = File.read(app)
				app_load_ary << JSON.parse(js)
			}
			
			len = Dir.entries(servdir).length-3
			@characters[servid][len] = nil
			
			app_load_ary.each {|app|
				p = PageWithProperties.new(app["properties"], app["fields"])
				
				charid = p.properties["charid"]
				#@characters[servid].add_page!(p, charid)
				@characters[servid][charid] = p
			}
		}
	end
	
	def self.save_char(servid, charid)
		c = @characters[servid][charid]
		
		chardir = File.join($config["datadir"], "charappmanager", "characters")
		servdir = File.join(chardir, servid.to_s)
		Dir.mkdir(servdir) unless Dir.exist?(servdir)
		filename = File.join(servdir, "char_#{charid}.json")
		
		if c.nil?   #Character does not exist
			if File.exist?(filename)   #Character deleted since last save
				File.rename(filename, File.join(servdir, "deletedchar_#{charid}.json"))
			end
			return
		end
		
		js = JSON.generate(c)
		
		File.write(filename, js, {:mode => 'w'})
		return
	end
	
	def self.save_config
		@characters.each {|servid, charlist|
			charlist.each_index {|app_i|
				save_char(servid, app_i)
			}
		}
	end
end