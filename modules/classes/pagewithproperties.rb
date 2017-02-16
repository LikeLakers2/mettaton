class PageWithProperties
	#####################
	######VARIABLES######
	#####################
	
	# @return [Hash[String => Object]] Data for this page -- useful for internal stuff that normally shouldn't be touched.
	#		{
	#			"charid" => 123
	#		}
	attr_accessor :data
	
	# @return [Hash[String => Object]] A list of properties for this page
	#		{
	#			"ownerid" => 98296942768967680,
	#			"Status" => "Pending"
	#		}
	attr_accessor :properties
	
	# @return [Hash[String => String]] The defined fields for this page
	#		{
	#			"Name" => "Flowey, God of Hyperdeath",
	#			"Age" => "???",
	#			"Gender" => "He's a fucking flower",
	#			"Basic Appearance" => "<http://i.imgur.com/Sw6aRCg.png> <https://i.imgur.com/VeHtcwql.png>",
	#			"Brief Bio" => "He hates people. He uses his vines to ~~fuck bees~~ entangle them and then choke a bitch to death. Also he's Asriel goddamn Dreemurr and he can transform into the God of Hyperdeath whenever he so chooses. He loves getting into fights and killing others.",
	#			"Theme Song" => "<https://www.youtube.com/watch?v=53WGSZVJFm4>"
	#		}
	attr_accessor :fields
	
	
	
	#####################
	#######METHODS#######
	#####################
	def initialize(properties = nil, fields = nil, data = nil)
		@data = data || {}
		@properties = properties || {}
		@fields = fields || {}
	end
	
	# Will grab from properties if it exists there, else grab from fields
	def [](name)
		case name.downcase
		when "data" then @data
		when "properties" then @properties
		when "fields" then @fields
		else @data[data_get(name)] || @properties[prop_get(name)] || @fields[field_get(name)]
		end
	end
	
	def get_key(name)
		data_get(name) || prop_get(name) || field_get(name)
	end
	
	#-----#
	
	def data_get(name)
		arb_get(:@data, name)
	end
	def data_set!(name, value)
		arb_set!(:@data, name, value)
	end
	def data_delete!(name)
		arb_delete!(:@data, name)
	end
	
	#-----#
	
	def prop_get(name)
		arb_get(:@properties, name)
	end
	def prop_set!(name, value)
		arb_set!(:@properties, name, value)
	end
	def prop_delete!(name)
		arb_delete!(:@properties, name)
	end
	
	#-----#
	
	def field_get(name)
		arb_get(:@fields, name)
	end
	def field_set!(name, value)
		arb_set!(:@fields, name, value)
	end
	def field_delete!(name)
		arb_delete!(:@fields, name)
	end
	
	#-----#
	
	# Arbitrary stuff
	def arb_get(sym, name)
		arb_type(sym).select {|k,v| k.downcase == name.downcase }.keys.first
	end
	
	def arb_set!(sym, name, value)
		d = arb_get(sym, name)
		name = arb_get(sym, name) || name
		d[name] = value
	end
	
	def arb_delete!(sym, name)
		d = arb_get(sym, name)
		name = arb_get(sym, name) || name
		d.delete name
	end
	
	def arb_type(sym)
		self.instance_variable_get(sym)
	end
	
	def key?(key)
		@data.key?(key) || @properties.key?(key) || @fields.key?(key)
	end
	
	#---------------#
	
	# __      _______ ________          __
	# \ \    / /_   _|  ____\ \        / /
	#  \ \  / /  | | | |__   \ \  /\  / / 
	#   \ \/ /   | | |  __|   \ \/  \/ /  
	#    \  /   _| |_| |____   \  /\  /   
	#     \/   |_____|______|   \/  \/    
	#
	
	# Calls #view_props and #view_fields with the proc, and returns them joined by a newline
	# @param &block [Proc] A proc that processes a key-value pair
	# @return [String] All the results from the proc, joined by a single newline
	def view(&block)
		(view_props {|k,v| yield k,v}) + "\n" + (view_fields {|k,v| yield k,v})
	end
	
	# Create output for a page, from @properties only
	# @param &block [Proc] A proc that processes a key-value pair
	# @return [String] All the results from the proc, joined by a single newline
	def view_props(&block)
		@properties.map {|k,v| yield k, v }.join("\n")
	end
	
	# Create output for a page, from @fields only
	# @param &block [Proc] A proc that processes a key-value pair
	# @return [String] All the results from the proc, joined by a single newline
	def view_fields(&block)
		@fields.map {|k,v| yield k, v }.join("\n")
	end
	
	#####################
	#####JSON#METHODS####
	#####################
	def to_json(*p)
		{
			"data" => @data,
			"properties" => @properties,
			"fields" => @fields
		}.to_json(*p)
	end
end