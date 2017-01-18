class CharacterDB < Wiki
	#  _      _____  _____ _______ 
	# | |    |_   _|/ ____|__   __|
	# | |      | | | (___    | |   
	# | |      | |  \___ \   | |   
	# | |____ _| |_ ____) |  | |   
	# |______|_____|_____/   |_|   
	#
	
	# Creates an array of strings, passing each character to &block and returning it in the output.
	# @param &block [Proc] A proc that will take a Character class object and return a string.
	# @return [Array<String>] The output as an array.
	def list(&block)
		output = []
		@pages.each {|page|
			next if page.nil?
			output << yield page
		}
		output
	end
end