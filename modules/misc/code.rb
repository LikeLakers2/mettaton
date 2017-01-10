module MiscMod
	extend Discordrb::Commands::CommandContainer
	
	#Diceroller
	command([:diceroll, :roll, :dr], max_args: 1) do |event, param = "1d20"|
		break unless check_event(event)
		s = param.scan(/(\d+)?(d)?(\d+)?/i)[0]
		# [["DICE", "d", "SIDES"], [nil, nil, nil]]
		
		dice = s[0].nil? ? 1 : s[0].to_i
		if dice == 0 #0dX
			event.respond "The dice rolls are somewhere else."
			break
		elsif dice > 100
			event.respond "I can't hold that many dice at once."
			break
		end
		
		sides = s[2].nil? ? 20 : s[2].to_i
		if sides == 0 #Xd0
			event.respond "A sideless die is a non-existant die, I always say."
			break
		elsif sides == 1 #Xd1
			event.respond "I can't roll a sphere."
			break
		elsif sides > 1000
			event.respond "The dice roll away."
			break
		end
		
		results = []
		if sides == 2
			if dice == 1
				#1d2
				coin = rand.round == 1 ? "heads" : "tails"
				"You flipped a coin and got `#{coin}`."
			else
				#Xd2
				dice.times {|i|
					results << rand.round # heads = 1
				}
				
				headcount = results.count(1)
				tailcount = results.length - headcount
				
				"You got `#{headcount}` heads and `#{tailcount}` tails."
			end
		else
			dice.times {|i|
				results << rand(1..sides)
			}
			
			event << "You rolled a `#{dice}d#{sides}` and got `#{results.join('`, `')}`."
			if dice >= 10
				event << "I also counted the number of times each number appears:"
				counter = []
				sides.times {|i|
					n = results.count(i+1)
					counter << "`#{i+1}`: #{n}" if n > 0
				}
				event << counter.join(',  ')
			end
		end
	end
end