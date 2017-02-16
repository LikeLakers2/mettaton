class Character < Page
	def is_owner?(userid)
		ownerid == userid.resolve_id
	end
	
	def id
		self["charid"]
	end
	alias_method :charid, :id
	
	def ownerid
		self["ownerid"] #Will change this to a proper attribute later
	end
	
	def name
		self["name"] || "Unnamed Character"
	end
	
	def load_from_json(file)
		# TODO: JSON loading
	end
	
end