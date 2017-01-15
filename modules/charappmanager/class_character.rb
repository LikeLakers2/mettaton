class Character < PageWithProperties
	def is_owner?(userid)
		@properties["ownerid"] == userid
	end
	
	def id
		get_key("charid") #Will change this to a proper attribute later
	end
	alias_method :charid, :id
	
	def ownerid
		get_key("ownerid") #Will change this to a proper attribute later
	end
	
	def load_from_json(file)
		# TODO: JSON loading
	end
end