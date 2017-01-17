class Wiki
	#####################
	######VARIABLES######
	#####################
	
	# @return [Array<PageWithProperties>] A list of pages for this wiki
	attr_accessor :pages
	
	# New wiki.
	# @param pages [Array<PageWithProperties>] Fill with these pages. Optional, defaults to empty.
	def initialize(pages = nil)
		@pages = pages || []
	end
	
	# Adds a page to the wiki.
	# @param page [PageWithProperties] The page to add to the wiki.
	# @param pos [Integer] The position to add it at. Defaults to nil, used internally to refer to the end of the wiki.
	def add_page!(page, pos = nil)
		pos ||= @pages.size
		
		@pages.insert(pos, page)
	end
	
	# Removes a page from the wiki.
	# @param page [Integer, PageWithProperties] The index of the page to remove. Can also be a Symbol to search for.
	def remove_page!(page)
		if page.is_a? Integer
			@pages.delete_at page
		else
			@pages.delete_at @pages.find_index(page)
		end
	end
	
	# We'll assume anything that isn't defined here is meant for the page list itself,
	# for readability reasons.
	def method_missing(sym, *args)
		@pages.send(sym, *args)
	end
	
	
	
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
end