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
	
end