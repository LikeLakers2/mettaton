module ArchivalUnit
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
end