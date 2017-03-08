module ArchivalUnit
	def self.idstore_update(bot)
		# Could implement pstore here, but I have no intention of dealing with Marshal stuff
		sfile = File.join($config["datadir"], "archivalunit", "fulllogs", "idstore") << ".json"
		old_store = File.exist?(sfile) ? JSON.parse(File.read(sfile, {encoding: "UTF-8"})) : {}
		#p "-"
		new_store = idstore_hash(bot)
		#p "-"
		combined_store = idstore_merge(old_store, new_store)
		
		unless old_store == combined_store
			File.write(sfile, JSON.generate(combined_store), {:mode => 'w'})
		end
	end
	
	def self.idstore_hash(bot)
		hs, hc, hr, hu = [{}, {}, {}, {}]
		
		bot.servers.each {|id,s|
			hs[id.to_s] = s.name
			s.channels.each {|c|
				hc[c.id.to_s] = c.name
			}
			s.roles.each {|r|
				hr[r.id.to_s] = r.name
			}
			#s.members.each {|m|
			#	hu[m.id.to_s] = m.distinct
			#}
		}
		bot.users.each_pair {|id,u|
			hu[id.to_s] = u.distinct
		}
		
		{
			'servers'=>hs,
			'channels'=>hc,
			'roles'=>hr,
			'users'=>hu
		}
	end
	
	def self.idstore_merge(old, new)
		old.merge(new){|k,vold,vnew|
			vold.merge(vnew){|vk,vvold,vvnew|
				# Sometimes the members hash can become corrupted and have nil stuff.
				vvnew || vvold
			}
		}
	end
end