module Discordrb
	class Bot
		def update_presence(data)
      # Friends list presences have no server ID so ignore these to not cause an error
      return unless data['guild_id']

      user_id = data['user']['id'].to_i
      server_id = data['guild_id'].to_i
      server = server(server_id)
      return unless server

      member_is_new = false

      if server.member_cached?(user_id)
        member = server.member(user_id)
      else
        # Don't cache if this is received just after someone leaves
        return if data['status'] == 'offline'

        # If the member is not cached yet, it means that it just came online from not being cached at all
        # due to large_threshold. Fortunately, Discord sends the entire member object in this case, and
        # not just a part of it - we can just cache this member directly
        member = Member.new(data, server, self)
        debug("Implicitly adding presence-obtained member #{user_id} to #{server_id} cache")

        member_is_new = true
      end

      username = data['user']['username']
      if username && !member_is_new # Don't set the username for newly-cached members
        debug "Implicitly updating presence-obtained information for member #{user_id}"
        member.update_username(username)
      end

      member.update_presence(data)

      member.avatar_id = data['user']['avatar'] if data['user']['avatar']

      server.cache_member(member)
    end
	end
end