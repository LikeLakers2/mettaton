class CharacterDB < Wiki
	def load_from_dir(str_dir, filename = "char_*.json")
		ary = [nil] * Dir.entries(str_dir).length-3
		
		Dir.glob(File.join(str_dir, filename)).each {|app|
			js = JSON.parse(File.read(app))
			c = Character.new(app["properties"], app["fields"], app["data"])
			ary[c.id] = c
		}
		
		new(ary)
	end
end