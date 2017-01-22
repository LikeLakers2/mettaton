class PageWithProperties
	#####################
	######VARIABLES######
	#####################
	
	# @return [Hash[String => Object]] A list of properties for this page
	#		{
	#			"ownerid" => 98296942768967680,
	#			"status" => "Pending",
	#		}
	attr_accessor :properties
	
	# @return [Hash[String => String]] The defined fields for this page
	#		{
	#			"Name" => "Flowey, God of Hyperdeath",
	#			"Age" => "???",
	#			"Gender" => "He's a fucking flower",
	#			"Appearance" => "http://i.imgur.com/Sw6aRCg.png https://i.imgur.com/VeHtcwql.png",
	#			"Brief Info" => "He hates people. He uses his vines to ~~fuck bees~~ entangle them and then choke a bitch to death. Also he's Asriel goddamn Dreemurr and he can transform into the God of Hyperdeath whenever he so chooses. He loves getting into fights and killing others.",
	#			"Theme Song" => "https://www.youtube.com/watch?v=53WGSZVJFm4"
	#		}
	attr_accessor :fields
	
	
	#####################
	#######METHODS#######
	#####################
	def initialize(properties = nil, fields = nil)
		@properties = properties || {}
		@fields = fields || {}
	end
	
	# Will grab from properties if it exists there, else grab from fields
	def [](name)
		if name == "properties" then @properties
		elsif name == "fields" then @fields
		else @properties[prop_get(name)] || @fields[field_get(name)]
		end
	end
	
	def get_key(name)
		prop_get(name) || field_get(name)
	end
	
	def prop_get(name)
		@properties.select {|k,v| k.downcase == name.downcase }.keys.first
	end
	
	def prop_set!(name, value)
		name = prop_get(name) || name
		@properties[name] = value
	end
	
	def field_get(name)
		@fields.select {|k,v| k.downcase == name.downcase }.keys.first
	end
	
	def field_set!(name, value)
		name = field_get(name) || name
		@fields[name] = value
	end
	
	def key?(key)
		@properties.key?[name] || @fields.key?[name] 
	end
	
	#####################
	#####JSON#METHODS####
	#####################
	def to_json(*p)
		{
			"properties" => @properties,
			"fields" => @fields
		}.to_json(*p)
	end
end