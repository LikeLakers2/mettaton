class CharacterDB < Wiki
	# Search function
	# @param field [String] The field name to search
	# @param op [Symbol] A symbol specifying what method to use to search
	# @param text [Object] Text to search with.
	def search(field, op, text, invert = false)
		@pages.select {|page|
			next if page.nil?
			page[field].send(op, text) unless invert
			!(page[field].send(op, text)) if invert
		}
	end
	
		search(field, :==, text, invert)
	end
	
		search(field, :include?, text, invert)
	end
	
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