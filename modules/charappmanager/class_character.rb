class Character < PageWithProperties
	def is_owner?(userid)
		@properties["ownerid"] == userid
	end
	
	def name
		["name"] || "Unnamed Character" #Will change this to a proper attribute later
	end
	
	def id
		["charid"] #Will change this to a proper attribute later
	end
	alias_method :charid, :id
	
	def ownerid
		["ownerid"] #Will change this to a proper attribute later
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
	#
	
	def view(&block)
		(view_props {|k,v| yield k,v}) + "\n" (view_fields {|k,v| yield k,v})
	end
	
	# Create output for a character, from @properties only
	# @param &block [Proc] A proc that processes a key-value pair
	# @return [String] All the results from the proc, joined by a single newline
	def view_props(&block)
		@properties.map {|k,v| yield k, v }.join("\n")
	end
	
	# Create output for a character, from @fields only
	# @param &block [Proc] A proc that processes a key-value pair
	# @return [String] All the results from the proc, joined by a single newline
	def view_fields(&block)
		@fields.map {|k,v| yield k, v }.join("\n")
	end
end