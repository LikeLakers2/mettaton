class CharacterDB < Wiki
	#   _____ ______          _____   _____ _    _ 
	#  / ____|  ____|   /\   |  __ \ / ____| |  | |
	# | (___ | |__     /  \  | |__) | |    | |__| |
	#  \___ \|  __|   / /\ \ |  _  /| |    |  __  |
	#  ____) | |____ / ____ \| | \ \| |____| |  | |
	# |_____/|______/_/    \_\_|  \_\\_____|_|  |_|
	#
	
	# Search function
	# @param field [String] The field name to search
	# @param op [Symbol] A symbol specifying what method to use to search
	# @param text [Object] Text to search with.
	# @return [Array<Character>] The results that match your search.
	def search(field, op, text, invert = false)
		@pages.select {|page|
			next if page.nil?
			page[field].send(op, text) unless invert
			!(page[field].send(op, text)) if invert
		}
	end
	
	def search_equals(field, text, invert = false)
		search(field, :==, text, invert)
	end
	
	def search_contains(field, text, invert = false)
		search(field, :include?, text, invert)
	end
	
	def search_regex(field, text, invert = false)
		search(field, :=~, text, invert)
	end
	
	#def search_not_equals(field, text)
	#	search(field, :==, text, true)
	#end
	
	#def search_not_contains(field, text)
	#	search(field, :include?, text, true)
	#end
	
	#def search_not_regex(field, text)
	#	search(field, :=~, text, true)
	#end
end