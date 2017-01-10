module CharAppManager
	#####################
	######VARIABLES######
	#####################
	
	# @return [Hash[Integer => Hash[Object => Object]]] The current registration states
	#   {USERID => {:step => :name, "name" => "Johnny", etc.}}
	attr_accessor :regstate
	
	
	#####################
	##REGISTER#COMMANDS##
	#####################
	command([:register, :reregister]) do |event, charid = nil|
		break unless check_event(event)
		if event.channel.private?
			event.respond "You should execute this in a server, you know."
		else
			rc = []
			rc[0] = event.author.role?(251795395863117834) #NPC
			rc[1] = event.author.role?(250917798845349888) || event.author.role?(251776958650777600) || check_admin(event)#Roleplayer || RP-Applicant
			if rc == [false, true]
				reg_start(event, charid) #if [256789485881262090].include? event.channel.id   #MTT: charappmanager
			else
				event.respond "You need the Roleplayer or RP-Applicant roles to do this!"
			end
		end
		#reg_start(event, charid) if [120331959703568386, 251776534812033026].include? event.channel.id   #/r/UT: truelab, roleplay-ooc
	end
	
	pm() do |event|
		reg_loop(event) if @regstate.has_key? event.user.id
	end
	
	#####################
	####REGISTRATION#####
	#######METHODS#######
	#####################
	def self.reg_start(event, charid)
		servid = event.server.id
		userid = event.user.id
		if charid.nil?
			event.respond ":mailbox_with_mail: Please check your DMs! If you don't receive one, check your privacy settings and try again!"
			@regstate[userid] = {
				:step => :checkforpremade,
				:stepdata => nil,
				:chardata => default_fields,
				:servid => servid,
				:charid => nil
			}
			msg = "Let's submit your character. First off, do you already have your character info typed out somewhere?"
			msg << "\nIf you do, please paste/upload it here now. Web links, full text, and file uploads are all accepted, and will be submitted and handled appropriately. (There is no specified format, so feel free to format this as you desire.)"
			msg << "\nIf you do not, type `no`, and you'll enter a mode where you can add and edit fields interactively."
			msg << "\n\nAt any time during this process, type `exit` to exit and discard everything."
			event.user.pm msg
		else
			charid = get_charid(event, servid, charid)
			return if !charid
			event.respond ":mailbox_with_mail: Please check your DMs! If you don't receive one, check your privacy settings and try again!"
			
			if is_owner?(servid, charid, userid)
				c = @characters[servid][charid]
				
				msg = ""
				if c.fields.key? "Prefilled Application"
					@regstate[userid] = {
						:step => :rereg_checkforpremade,
						:stepdata => @characters[servid][charid].fields["Prefilled Application"],
						:chardata => @characters[servid][charid].fields.clone,
						:servid => servid,
						:charid => charid
					}
					msg << "You appear to have a application that was filled out non-interactively. Do you wish to edit this?\n"
					msg << "Type `yes` to edit, or type `no` to keep and enter an interactive field-editing mode.\n"
					msg << "You may also type `delete` if you wish to delete this and enter the interactive field-editing mode.\n"
					msg << "\nAt any time during this process, type `exit` to exit and discard everything."
				else
					@regstate[userid] = {
						:step => :fieldchoice,
						:stepdata => nil,
						:chardata => @characters[servid][charid].fields.clone,
						:servid => servid,
						:charid => charid
					}
					msg << "Let's edit that character info, shall we?"
					msg << "\n\n#{msg_field_list(userid)}"
				end
				event.user.pm msg
				
				chardatamsg =  "As a reminder, here is what your application looks like already.\n\n"
				@regstate[userid][:chardata].each {|k,v|
					chardatamsg << "`#{k}`: #{v}\n"
				}
				event.user.pm chardatamsg
			else
				event.respond "You must be the owner of the character to do this!"
			end
		end
	end
	
	##############################
	##############################
	def self.reg_loop(event)
		userid = event.user.id
		text = event.content
		
		if text == "exit"
			event.respond "Okay, goodbye."
			@regstate.delete userid
			return
		end
		
		msg = ""
		case @regstate[userid][:step]
		when :checkforpremade   #Before we start doing field stuff, we're allowing them to have it already typed out
			case text.downcase
			when "no"
				@regstate[userid][:step] = :fieldchoice
				
				msg << "Okay then."
				if is_rereg?(userid)
					msg << "Let's edit some of that info on your character application, shall we?"
				else
					msg << "\nLet's put some info into your character application, shall we?"
				end
				msg << "\n\n" << msg_field_list(userid)
			else
				#Perhaps give an option to go to field stuff anyways
				@regstate[userid][:step] = :checkforpremade_confirm
				@regstate[userid][:stepdata] = text
				event.message.attachments.each {|file|
					@regstate[userid][:stepdata] << " " << file.url
				}
				
				msg << "Are you sure this is what you wish to submit?"
				msg << "\nType `yes` to submit. Type `no` if you wish to change your previous input."
			end
		##############################
		when :checkforpremade_confirm
			case text.downcase
			when "no"   #They want to change
				@regstate[userid][:step] = :checkforpremade
				@regstate[userid][:stepdata] = nil
				
				msg << "Please paste/upload your corrected application."
				msg << "\nYou may also type `no` to skip this step, in cases such as if you meant to do so in the first place."
			when "yes"   #They want to submit
				@regstate[userid][:chardata] = {"Prefilled Application"=>@regstate[userid][:stepdata]}
				reg_end(event)
			end
		##############################
		when :rereg_checkforpremade
			case text.downcase
			when "no"   #Keep, enter interactive mode
				@regstate[userid][:step] = :fieldchoice
				@regstate[userid][:stepdata] = nil
				
				msg << "OK. Let's edit that character info, shall we?"
				msg << "\n\n#{msg_field_list(userid)}"
			when "delete"   #Delete, enter interactive mode
				@regstate[userid][:step] = :fieldchoice
				@regstate[userid][:stepdata] = nil
				@regstate[userid][:chardata].delete "Prefilled Application"
				@regstate[userid][:chardata] = default_fields
				
				msg << "OK. Let's edit that character info, shall we?"
				msg << "\n\n#{msg_field_list(userid)}"
			when "yes"   #Edit
				@regstate[userid][:step] = :checkforpremade
				@regstate[userid][:stepdata] = nil
				
				msg << "Please paste/upload your corrected application."
				msg << "\nYou may also type `no` to skip this step, in cases such as if you meant to do so in the first place."
			end
		##############################
		when :fieldchoice   #When choice is made
			case text.downcase
			when "preview" #Preview
				@regstate[userid][:chardata].each {|k,v|
					msg << "`#{k}`: #{v}\n"
				}
			when "done" #Done, submit it
				if msg_get_fields_left(userid).empty?
					reg_end(event)
				else
					msg << "You must fill out all required fields."
				end
			else
				case text.downcase[0..6]
				when "delete "
					key_request = text.downcase[7..-1]
					key = @regstate[userid][:chardata].select {|k,v| k.downcase == key_request }.keys.first
					
					if key.nil?
						msg << "That field does not exist."
					elsif default_fields.keys.include? key
						@regstate[userid][:chardata][key] = ""
						msg << "Field `#{key}` has been wiped."
						msg << "\n\n" << msg_field_list(userid)
					else
						@regstate[userid][:chardata].delete key
						if key == "Prefilled Application"
							@regstate[userid][:chardata] = default_fields_merge(@regstate[userid][:chardata])
						end
						msg << "Field `#{key}` has been deleted."
						msg << "\n\n" << msg_field_list(userid)
					end
				else
					#Switch to the fieldtextentry step
					@regstate[userid][:step] = :fieldtextentry
					#A bit of trickery here in case upper/lowercase is different
					key = @regstate[userid][:chardata].select {|k,v| k.downcase == text.downcase }
					if key.empty?  #New field
						@regstate[userid][:stepdata] = text
						#Initialize that choice's field
						@regstate[userid][:chardata][text] ||= ""
					else  #Pre-defined field
						@regstate[userid][:stepdata] = key.keys.first
					end
					
					msg << "And what would you like the field `#{text}` to say?"
				end
			end
		##############################
		when :fieldtextentry   #When text is entered after a choice
			#Set the field
			field = @regstate[userid][:stepdata]
			@regstate[userid][:chardata][field] = text
			event.message.attachments.each {|file|
				@regstate[userid][:chardata][field] << " " << file.url
			}
			
			#Switch back to the fieldchoice step
			@regstate[userid][:step] = :fieldchoice
			@regstate[userid][:stepdata] = nil
			
			msg << "Field `#{field}` has been changed.\n\n#{msg_field_list(userid)}"
		end
		#p @regstate
		event.respond msg unless msg.empty?
	end
	##############################
	##############################
	
	def self.reg_end(event)
		userid = event.user.id
		servid = @regstate[userid][:servid]
		if is_rereg?(userid)
			charid = @regstate[userid][:charid]
			props = {
				"Status" => "Pending"
			}.merge(@characters[servid][charid].properties) {|k,old,new| old}
		else
			charid = @characters[servid].empty? ? 1 : @characters[servid].length
			props = default_props_merge({
				"charid" => charid,
				"ownerid" => userid
			})
		end
		
		chardata_temp = @regstate[userid][:chardata]
		chardata = {}
		chardata_temp.each {|k,v|
			chardata[k] = url_block(v)
		}
		
		#@characters[servid] ||= Wiki.new
		@characters[servid] ||= []
		#@characters[servid].add_page!(PageWithProperties.new(props, chardata),charid)
		@characters[servid][charid] = PageWithProperties.new(props, chardata)
		
		msg_info = ""
		msg_info << servcfg(servid)["prepend"]
		if is_rereg?(userid)
			msg_info << "**RESUBMISSION FOR CHARACTER ID #{charid}**\n"
		end
		msg_info << "Character application from **`#{event.user.distinct}`** (ID: #{event.user.id})\n"
		msg = "#{msg_info}```\n"
		chardata.each {|k,v|
			msg << "#{k}: #{v}\n\n"
		}
		msg << "```\n"
		msg << "To change the status of this character, type `rp!<approve|pending|deny> #{charid}`."
		msg_info << "To change the status of this character, type `rp!<approve|pending|deny> #{charid}`."
		
		if msg.length >= Discordrb::CHARACTER_LIMIT
			time = (Time.now.utc - (60*60*5)).to_s << "-5"
			filename = File.join($config["tempdir"], "#{servid}_#{userid}_#{time}.txt")
			filename.gsub!(/:/, "-")
			
			File.write(filename, msg, {:mode => 'a'})
			
			f = File.open(filename, "r")
			
			$bot.send_file(servcfg(servid)["logchannel"], f, caption: msg_info)
		else
			$bot.send_message(servcfg(servid)["logchannel"], msg)
		end
		
		save_char(servid, charid)
		end_msg = "Your application has been #{"re" if is_rereg?(userid)}submitted and will be reviewed at the next available opportunity."
		end_msg << "\nYour character's ID is `#{charid.to_s}`. You may use either this ID, or the character's name, when performing actions upon it with `rp!charmanage`."
		event.respond end_msg
		@regstate.delete userid
	end
	
	#####################
	####MESSAGE#TEXTS####
	#####################
	
	def self.msg_field_list(userid)
		msg = ""
		fieldsleft = msg_get_fields_left(userid).keys
		msg << "Required field(s) left to specify: `#{fieldsleft.join('`, `')}`\n" unless fieldsleft.empty?
		fieldsdone = msg_get_fields_done(userid).keys
		msg << "Field(s) already specified: `#{fieldsdone.join('`, `')}`\n" unless fieldsdone.empty?
		msg << "Type a field name from the selection above to edit it, or type any text not specified here to create a custom field.\n"
		unless fieldsdone.empty?
			msg << "\nIf you wish to delete a field, type `delete` followed by the name of the field. For example, `delete name` to delete the `Name` field.\n"
			msg << "If you wish to preview how your application will look, type `preview`.\n" unless fieldsdone.empty?
		end
		msg << "If you wish to submit your application as is, type `done`.\n" if fieldsleft.empty?
		msg << "\nIf at any time you wish to exit and discard your character application, type `exit`."
		msg
	end
	
	def self.msg_get_fields_left(userid)
		@regstate[userid][:chardata].select {|k,v| v.empty? }
	end
	def self.msg_get_fields_done(userid)
		@regstate[userid][:chardata].select {|k,v| !v.empty?}
	end
	
	#####################
	###HELPER##METHODS###
	#####################
	def self.default_fields
		{
			"Name" => "",
			"Age" => "",
			"Gender" => "",
			"Basic Appearance" => "",
			"Brief Bio" => ""
		}
	end
	
	def self.default_props
		{
			"charid" => 0,
			"ownerid" => 0,
			"Status" => "Pending"
		}
	end
	
	def self.default_fields_merge(hash)
		default_merge(hash, default_fields)
	end
	
	def self.default_props_merge(hash)
		default_merge(hash, default_props)
	end
	
	def self.default_merge(hash, default_hash)
		newhash = hash.clone
		default_hash.each_pair {|dk,dv|
			hash.each_pair {|k,v|
				if k.downcase == dk.downcase
					newhash.delete(k)
					newhash[dk] = v
				end
			}
		}
		newhash.merge(default_hash) {|k,old,new| old}
	end
	
	def self.is_rereg?(userid)
		!(@regstate[userid][:charid].nil?)
	end
	
	
	def self.servcfg(servid)
		$modconfig["charappmanager"]["servcfg"][servid.to_s] || default_servcfg
	end
	
	def self.default_servcfg
		{
			"logchannel"=>256789495104536577,
			"prepend"=>""
		}
	end
end