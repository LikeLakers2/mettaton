module CharAppManager
	#####################
	###APP##MANAGEMENT###
	#####################
	
	command([:charmanage, :cm]) do |event, action = nil, *params|
		break unless check_event(event)
		if event.channel.private?
			event.respond "You should execute this in a server, you know."
		elsif action.nil?
			event << "You didn't specify what you want to do."
			event << "Available actions: `#{list_cm_actions.join('`, `')}`"
			event << "You may also specify a character name in place of an action as an alias to view it."
			event << "Please note that it must be the full valid name for a character name to work."
		else
			act = "cm_#{action.downcase}".to_sym
			if self.respond_to?(act)
				#rp!cm <act>
				self.send(act, event, params)
			elsif !(get_charid2(event.server.id, action).empty?)
				#rp!cm <character>
				self.send(:cm_view, event, [action, *params])
			else
				event << "I didn't understand what you wanted me to do."
				event << "Available actions: `#{list_cm_actions.join('`, `')}`"
				event << "You may also specify a character name in place of an action as an alias to view it."
				event << "Please note that it must be the full valid name for a character name to work."
			end
		end
		nil
	end
	
	#    view => Character#view
	#     set => PageWithProperties#field_set!
	# setprop => PageWithProperties#prop_set!
	#    list => CharacterDB#list
	#  search => Wiki#search
	#  delete => Wiki[n] = nil              #TODO
	command([:view, :set, :setprop, :list, :search, :delete]) do |event, *params|
		event.bot.execute_command(:charmanage, event, [event.command.name, *params])
	end
	
	def self.cm_view(event, params = nil)
		servid = event.server.id
		charid = get_charid(event, servid, params[0])
		return if !charid
		
		msg = ""
		#-------------#
		propmsg = []
		fieldmsg = []
		c = @characters[servid][charid]
		
		#####PROPERTIES#####
		propmsg << "Info for Character ##{charid}:"
		c.properties.each_pair {|k,v|
			case k
			when "charid" then next
			when "ownerid"
				dist = get_distinct(event, v)
				if dist.nil?
					propmsg << "`[Property] Owner ID`: #{v} (User has left this server)"
				else
					propmsg << "`[Property] Owner`: **#{dist}**"
				end
			else
				propmsg << "`[Property] #{k}`: #{v}"
			end
		}
		
		#####CHAR#FIELDS#####
		c.fields.each {|k,v|
			fieldmsg << "`#{k}`: #{v}"
		}
		
		cl = Discordrb::CHARACTER_LIMIT
		pl = 0; fl = 0
		p_j = propmsg.join("\n");
		f_j = fieldmsg.join("\n")
		pl = p_j.length; fl = f_j.length
		if pl+fl+1 > cl   #If, combined with a line break, it would be over the character limit
			if pl > cl or fl > cl   #If either would be over the character limit
				#We should send it as a file
				sv_fn = chardir = File.join($config["datadir"], "charappmanager", "characters", servid.to_s, "char_#{charid}.json")
				temp_fn = File.join($config["tempdir"], "#{servid}_char_#{charid}.txt")
				
				unless File.exist?(temp_fn) and test('<', sv_fn, temp_fn)
					msg_to_dump = "#{p_j}\n#{f_j}"
					
					File.write(temp_fn, msg_to_dump, {:mode => 'w'})
				end
				
				f = File.open(temp_fn, "r")
				msg_info = "The result was too long, so I've dumped it to a file."
				event.send_file(f, caption: msg_info)
			else
				#Send it as two separate messages
				event.respond p_j
				event.respond f_j
			end
		else
			msg << "#{p_j}\n#{f_j}"
		end
		#-------------#
		
		event.respond msg unless msg.empty?
	end
	
	def self.cm_set(event, params = nil)
		userid = event.user.id
		servid = event.server.id
		charid = get_charid(event, servid, params[0])
		return if !charid
		
		msg = ""
		if is_owner?(servid, charid, userid) or check_admin(event)
			field = params.empty? ? nil : params[1]
			field_text = params.empty? ? nil : (params[2].nil? ? nil : get_text_param(event, params))
			#key = @characters[servid][charid].field_get(field)
			
			if field.nil?
				msg = "Please specify a field to edit!"
			elsif field_text.nil?
				key = @characters[servid][charid].field_get(field)
				msg << "What do you want to do with `#{field}`?\n"
				if key.nil?
					msg << "If you want to create that field, just put some text after the field name!"
				else
					msg << "If you want to edit that field, just put some text after the field name!\n"
					msg << "Alternatively, if you want to delete that field, just type `delete` after the field name."
				end
			elsif field_text.downcase == "delete"
				key = @characters[servid][charid].field_get(field)
				if key.nil?
					msg = "That field does not exist."
				elsif default_fields.keys.include? key
					@characters[servid][charid].fields[key] = ""
					msg = "Field `#{key}` for that character has been wiped."
				else
					@characters[servid][charid].fields.delete key
					msg = "Field `#{key}` for that character has been deleted."
				end
			else
				key = @characters[servid][charid].field_get(field)
				if key.nil?
					@characters[servid][charid].fields[field] = url_block(field_text)
					msg = "Field `#{field}` for that character has been created."
				else
					@characters[servid][charid].fields[key] = url_block(field_text)
					msg = "Field `#{key}` for that character has been changed."
				end
			end
			save_char(servid, charid)
		else
			msg = "You do not have permission to do that!"
		end
		
		event.respond msg unless msg.empty?
	end
	
	def self.cm_setprop(event, params = nil)
		userid = event.user.id
		servid = event.server.id
		charid = get_charid(event, servid, params[0])
		return if !charid
		
		msg = ""
		if check_admin(event)
			prop = params.empty? ? nil : params[1]
			prop_text = params.empty? ? nil : (params[2].nil? ? nil : get_text_param(event, params))
			#key = @characters[servid][charid].prop_get(prop)
			
			if prop.nil?
				msg = "Please specify a property to edit!"
			elsif prop == "charid"
				msg = "You are not allowed to set the character ID."
			elsif prop_text.nil?
				key = @characters[servid][charid].prop_get(prop)
				msg << "What do you want to do with `#{prop}`?\n"
				if key.nil?
					msg << "If you want to create that prop, just put some text after the prop name!"
				else
					msg << "If you want to edit that prop, just put some text after the prop name!\n"
					msg << "Alternatively, if you want to delete that prop, just type `delete` after the prop name."
				end
			elsif prop_text.downcase == "delete"
				key = @characters[servid][charid].prop_get(prop)
				if key.nil?
					msg = "That property does not exist."
				elsif default_fields.keys.include? key
					@characters[servid][charid].properties[key] = ""
					msg = "Property `#{key}` for that character has been wiped."
				else
					@characters[servid][charid].properties.delete key
					msg = "Property `#{key}` for that character has been deleted."
				end
			else
				key = @characters[servid][charid].prop_get(prop)
				if key.nil?
					@characters[servid][charid].properties[prop] = prop_text
					msg = "Property `#{prop}` for that character has been created."
				else
					prop_text = prop_text.to_i if key == "ownerid"
					@characters[servid][charid].properties[key] = prop_text
					msg = "Property `#{key}` for that character has been changed."
				end
			end
			save_char(servid, charid)
		else
			msg = "You are not allowed to set properties on characters."
		end
		
		event.respond msg unless msg.empty?
	end
	
	def self.cm_list(event, params = nil)
		servid = event.server.id
		if @characters[servid].empty?
			event.respond "This server has no characters registered yet. Be the first!"
			return
		end
		pagination = make_list(event, @characters[servid])
		
		page = params.empty? ? 0 : params[0]
		page2 = page.to_s.downcase
		if page2 == "all"
			userid = event.user.id
			
			ftext = "List of all characters:\n\n"
			ftext << pagination.join("\n")
			
			time = (Time.now.utc - (60*60*5)).to_s << "-5"
			filename = File.join($config["tempdir"], "#{servid}_#{userid}_#{time}.txt")
			filename.gsub!(/:/, "-")
			
			File.write(filename, ftext, {:mode => 'w'})
			
			f = File.open(filename, "r")
			
			event.user.send_file(f, "Here's the full list of characters.")
			event.respond ":mailbox_with_mail: Please check your DMs! If you don't receive one, check your privacy settings and try again!"
		elsif page2 == "@me" or page2 == "me"
			userid = event.user.id
			pagination = make_list(event, @characters[servid].select {|c|
				next if c.nil?
				c["ownerid"] == userid
			})
			text = "List of all characters owned by **#{event.user.distinct}**:\n\n"
			text << pagination.join("\n")
			
			event.respond text
		else
			event.respond list_to_string("List of all characters:", pagination, params[0], 10)
		end
	end
	
	def self.cm_search(event, params = nil)
		#rp!am search "FIELD/PROP" OP "TEXT" 
		#Optionally, allow searching through last results
		#OPERATORS:
		# = EQ    || EQUALS   (text == searchtext)
		# ~ HAS   || CONTAINS   (text.match?(/.*searchtext.*/i))
		# REG `regex` || REGEX   (Regexp.new(regex).match(text))
		# !op NOT || NOT
		
		#p params
		field = params[0]
		op = params[1]
		searchtext = params[2]
		servid = event.server.id
		page = params.nil? ? 1 : (params[3].nil? ? 1 : params[3])
		
		msg = ""
		if field.nil?
			msg = "Please specify a field to search!"
		elsif op.nil?
			if !(event.message.mentions.empty?)
				#rp!cm search <@mention>
				self.send(:cm_search, event, ["owner", "EQ", event.message.mentions[0].mention])
			else
				self.send(:cm_search, event, ["Name", "CO", field])
				#msg = "Please specify a correct search operator to use!\n"
				#msg << "You may also specify a character name, or mention someone to search all their characters."
			end
		elsif searchtext.nil?
			msg = "Please specify something to search with!"
		else
			op = operator_check(op)
			if op.nil?
				msg = "Please specify a valid search operator!"
			else
				if field.downcase == "owner"
					field = "ownerid"
					searchtext = event.message.mentions[0].id.to_s
				end
				if op == "REGEX" || op == "!REGEX"
					# ^\s*\/.*\/\w*\s*$
					searchtext.gsub!(/^\s*\//i, '')
					searchtext.gsub!(/\/\w*\s*$/i, '')
				end
				results = do_search(servid, field, op, searchtext)
				if results.length == 0
					msg = "No results!"
				else
					results_output = make_list(event, results)
					msg = list_to_string("List of results:", results_output, page, 20)
				end
			end
		end
		event.respond msg unless msg.empty?
	end
	
	def self.cm_delete(event, params = nil)
		userid = event.user.id
		servid = event.server.id
		charid = get_charid(event, servid, params[0])
		return if !charid
		
		msg = ""
		if is_owner?(servid, charid, userid) or check_admin(event)
			if params[1] == "confirm"
				@characters[servid][charid] = nil
				msg = "Character has been deleted."
				save_char(servid, charid)
			else
				msg = "**Are you sure you wish to delete this character?**\n"
				msg << "This action *is* reversible, but only by the owner of this bot.\n"
				msg << "Type `#{event.content} confirm` to confirm that you wish to delete."
			end
		else
			msg = "You do not have permission to delete that character!"
		end
		event.respond msg unless msg.empty?
	end
	
	
	#####################
	####LIST##METHODS####
	#####################
	def self.list_to_string(prepend, list, page = nil, results_per_page = 10)
		page = page.nil? ? 0 : page.to_i-1
		page_limit = (list.length-1).div(results_per_page)+1
		
		list_page = list_pagination(list, page, results_per_page)
		
		msg = "#{prepend}\n\n"
		list_page.each {|l| msg << "#{l}\n"}
		if page_limit > 1
			msg << "\nPage #{page+1}/#{page_limit}"
		end
		msg
	end
	def self.make_list(event, array_of_characters)
		output = []
		array_of_characters.each {|char|
			next if char.nil?
			listnum = output.length+1
			
			name = char["Name"]
			name = name.nil? ? "Unnamed Character" : name
			
			charid = char["charid"]
			
			ownerid = char["ownerid"]
			ownerdist = get_distinct(event, char["ownerid"])
			ownertext = ownerdist.nil? ? "OwnerID: #{ownerid}" : "Owner: **#{ownerdist}**"
			
			text = "`#{listnum}.` #{name} (ID#`#{charid}`; #{ownertext})"
			
			output << text
		}
		output
	end
	
	def self.list_pagination(array, page = 0, results_per_page = 10)
		a_start = results_per_page * page
		return [] if a_start >= array.length || a_start <= -results_per_page
		a_end = a_start + results_per_page - 1
		array[a_start..a_end]
	end
	
	
	#####################
	###SEARCH##METHODS###
	#####################
	def self.do_search(servid, field, op, searchtext)
		do_search_repeat(@characters[servid], field, op, searchtext)
	end
	
	def self.do_search_repeat(array, field, op, searchtext)
		#op = operator_check(op)
		return [] if op.nil?
		searchtext.downcase!
		array.select {|char|
			next if char.nil?
			f = char[field]
			if f.nil? then next
			else
				f = f.to_s.downcase
				true if case op
				when "==" then f == searchtext
				when "!==" then f != searchtext
				when "=~" then f.include? searchtext
				when "!~=" then !f.include? searchtext
				when "REGEX" then f =~ /#{searchtext}/i
				when "!REGEX" then !(f =~ /#{searchtext}/i)
				end
			end
		}
	end
	
	def self.operator_check(op)
		case op.upcase
		when "EQ", "EQUALS", "=", "=="
			return "=="
		when "CO", "CONTAINS", "~", "~=", "=~"
			return "=~"
		when "REG", "REGEX"
			return "REGEX"
		when "!EQ", "!EQUALS", "!=", "!=="
			return "!=="
		when "!CO", "!CONTAINS", "!~", "!~=", "!=~"
			return "!=~"
		when "!REG", "!REGEX"
			return "!REGEX"
		else
			return nil
		end
	end
	
	#####################
	###HELPER##METHODS###
	#####################
	def self.list_cm_actions
		self.methods.collect {|m| m[3..-1] if m[0..2] == "cm_"}.compact
	end
	
	def self.is_owner?(servid, charid, userid)
		@characters[servid][charid]["ownerid"] == userid
	end
	
	def self.get_distinct(event, ownerid)
		u = event.server.member(ownerid)
		return u.nil? ? nil : u.distinct
	end
	
	def self.get_charid(event, servid, charid_or_name)
		if charid_or_name.nil?   #No character ID specified
			event << "Please specify a character ID or name."
			return false
		end
		
		cids = get_charid2(servid, charid_or_name)
		
		if cids.length == 0   #Invalid and empty character IDs will return an empty array
			event << "That character could not be found!"
			return false
		elsif cids.length > 1
			#Just in case someone wants to be sneaky and use a charid as a name
			cids2 = cids.select {|char|
				char["charid"] == charid_or_name.to_i
			}.first
			if cids2.nil?
				msg = "Your character name matched multiple results.\n"
				msg << "Please re-execute this commend with the corresponding ID from the list below:"
				cids_output = make_list(event, cids)
				event << list_to_string(msg, cids_output, 1, 10)
				return false
			else
				return cids2.properties["charid"]
			end
		else
			return cids[0].properties["charid"]
		end
		#cid.length > 1 ? nil : cid[0]
	end
	
	def self.get_charid2(servid, charid_or_name)
		return nil if charid_or_name.nil?
		@characters[servid].select {|char|
			next if char.nil?
			char["charid"] == charid_or_name.to_i || (char["Name"].nil? ? false : char["Name"].downcase == charid_or_name.to_s.downcase)
		}
	end
	
	def self.get_text_param(event, params)
		pos = 0
		c = event.content
		
		bpos = c.index(params[1])
		pos = bpos+params[1].length
		
		pos -= 1 unless (c[bpos-1] == '"' && c[pos] == '"')
		pos += 2
		
		text = c[pos..-1]
		text = text[1..-2] if (text.start_with?('"') && text.end_with?('"'))
		text
	end
end