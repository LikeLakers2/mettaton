class Character < PageWithProperties
	def is_owner?(userid)
		@properties["ownerid"] == userid
	end
	
	def id
		@properties["charid"] #Will change this to a proper attribute later
	end
	
	def load_from_json(file)
		# TODO: JSON loading
	end
end