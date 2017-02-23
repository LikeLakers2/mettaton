module ArchivalUnit
	# @return [Hash[Integer => String]] Snowflakes to server names
	attr_accessor :servers
	# @return [Hash[Integer => String]] Snowflakes to channel names
	attr_accessor :channels
	# @return [Hash[Integer => String]] Snowflakes to role names
	attr_accessor :roles
	# @return [Hash[Integer => String]] Snowflakes to user distincts
	attr_accessor :users
	
	def self.idstore_update(bot)
		h = idstore_hash(bot)
		JSON.generate(h)
	end
	
	def self.idstore_hash(bot)
		hs, hc, hr, hu = [{}, {}, {}, {}]
		bot.servers.each {|id,s|
			hs[id] = s.name
			s.channels.each {|c|
				hc[c.id] = c.name
			}
			s.roles.each {|r|
				hr[r.id] = r.name
			}
		}
		bot.users.each {|id, u|
			hu[id] = u.distinct
		}
		{
			'servers'=>hs,
			'channels'=>hc,
			'roles'=>hr,
			'users'=>hu
		}
	end
	
	#def self.idstore_hash_old(bot)
	#	{
	#		'servers'=>idu_servers(bot),
	#		'channels'=>idu_channels(bot),
	#		'roles'=>idu_roles(bot),
	#		'users'=>idu_users(bot)
	#	}
	#end
	
	#def self.idu_servers(bot)
	#	h = {}
	#	bot.servers.each {|id, s|
	#		h[id] = s.name
	#	}
	#	h
	#end
	
	#def self.idu_channels(bot)
	#	h = {}
	#	bot.servers.each {|id, s|
	#		s.channels.each {|c|
	#			h[c.id] = c.name
	#		}
	#	}
	#	h
	#end
	
	#def self.idu_roles(bot)
	#	h = {}
	#	bot.servers.each {|id, s|
	#		s.roles.each {|r|
	#			h[r.id] = r.name
	#		}
	#	}
	#	h
	#end
	
	def self.idu_users(bot)
		h = {}
		bot.users.each {|id, u|
			h[id] = u.distinct
		}
		h
	end
end