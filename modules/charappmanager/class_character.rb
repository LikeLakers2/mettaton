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
	
	# Outputs the character based on a template
	# {name} will be replaced with the field name
	# {text} will be replaced with the text
	# @param 
	# @param line [String] How a single field line should be output
	# @param propline [String] How a single property line should be output
	# @param
	
	# Create output for a character
	# @param properties [true, false] Whether or not to include the properties
	# @param fields [true, false] Whether or not to include the fields
	# @return [String] The output.
	def view(properties = true, fields = true)
		result = []
		
		(@properties.each {|k,v|
			result << view_field("[Property] #{k}", v)
		}) if properties
		
		(@fields.each {|k,v|
			result << view_field(k, v)
		}) if fields
		
		result.join("\n")
	end
	
	def view_field(name, text)
		"`#{name}`: #{text}"
	end
end