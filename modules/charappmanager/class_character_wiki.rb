class CharacterDB < Wiki
	# Returns a new CharacterDB, trimmed down to the search results.
	def search
		@pages.select {|page|
			next if page.nil?
			yield page
		}
	end
	
	def search_equals(field, text)
		search do |page|
			page[field] == text
		end
	end
	
	def search_contains(field, text)
		search do |page|
			page[field].include? text
		end
	end
	
	def search_regex(field, text)
		search do |page|
			page[field] =~ text
		end
	end
end