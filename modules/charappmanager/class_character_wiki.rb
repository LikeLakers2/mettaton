class CharacterDB < Wiki
	# Search function
	# @param field [String] The field name to search
	# @param op [Symbol] A symbol specifying what method to use to search
	# @param text [Object] Text to search with.
	def search_op(field, op, text, invert = false)
		@pages.select {|page|
			next if page.nil?
			page[field].send(op, text) unless invert
			!(page[field].send(op, text)) if invert
		}
	end
	
	# Returns a new CharacterDB, trimmed down to the search results.
	def search
		@pages.select {|page|
			next if page.nil?
			yield page
		}
	end
	
	def search_equals(field, text)
		search_op(field, :==, text)
	end
	
	def search_contains(field, text)
		search_op(field, :include?, text)
	end
	
	def search_regex(field, text)
		search_op(field, :=~, text)
	end
	
	
	def search_not
		s = search do |p|
					yield page
				end
				
		@pages.reject {|page| s.include? page}
	end
	
	def search_not_equals(field, text)
		search_op(field, :==, text, true)
	end
	
	def search_not_contains(field, text)
		search_op(field, :include?, text, true)
	end
	
	def search_not_regex(field, text)
		search_op(field, :=~, text, true)
	end
end