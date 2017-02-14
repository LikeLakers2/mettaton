class Character < PageWithProperties
	def is_owner?(userid)
		ownerid == userid.resolve_id
	end
	
	def id
		["charid"]
	end
	alias_method :charid, :id
	
	def ownerid
		["ownerid"] #Will change this to a proper attribute later
	end
	
	def name
		["name"] || "Unnamed Character"
	end
	
	def load_from_json(file)
		# TODO: JSON loading
	end
	
end