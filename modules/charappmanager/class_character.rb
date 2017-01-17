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
	
	
	# __      _______ ________          __
	# \ \    / /_   _|  ____\ \        / /
	#  \ \  / /  | | | |__   \ \  /\  / / 
	#   \ \/ /   | | |  __|   \ \/  \/ /  
	#    \  /   _| |_| |____   \  /\  /   
	#     \/   |_____|______|   \/  \/    
	
	# Outputs the text based on a template
	# {name} will be replaced with the field name
	# {text} will be replaced with the text
	# @param 
	# @param line [String] How a single field line should be output
	# @param propline [String] How a single property line should be output
	# @param
	def view()
		
	end
end