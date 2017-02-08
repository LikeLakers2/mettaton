# mettaton
A serious bot for once. This is the code that runs Mettaton on [/r/Undertale](https://discord.gg/undertale)'s Discord server. Revel in my shitty coding.

I will not provide support if you decide to run your own copy of this bot. With that in mind, I will also not provide support for third-party-run copies of this bot, and cannot guarantee that they will be free of malicious code.

If you wish to verify whether a copy of this bot is the one I, LikeLakers2/MichiRecRoom, run, here is the Username, discriminator, and user ID for me and my bot:

* The bot: **Mettaton#6421** (260783424908951553) (Will be marked with a bot tag)
* The coder: **MichiRecRoom#9507** (98296942768967680)

...If you're expecting an invite link to invite the bot to your server, sorry. This is a private bot. I might change this in the future though.

## Suggesting features or fixes
Feel free to [create an issue](https://github.com/LikeLakers2/mettaton/issues/new) to suggest new features or fixes! PRs are also allowed, though there is no guarantee I will merge them.

If you wanna see what I have in mind to add or change about this, [check the roadmap!](https://github.com/LikeLakers2/mettaton/projects/1)

## Dependencies
If you were to use this bot without any modifications to the code, you would need the following gems to obtain all functionality:

* [discordrb v3.1.1](https://rubygems.org/gems/discordrb/versions/3.1.1) -- Currently awaiting testing on v3.2.0, some parts of the code (namely, the [patches folder](/patching)) were made for v3.1.1 and do not work on v3.2.0
* [rest-client](https://rubygems.org/gems/rest-client) -- This is installed as a dependency by discordrb. I use it within my eval command to allow me to execute code from a file attached to a message, rather than be limited to what discord allows me to send as message content.
* [json](https://rubygems.org/gems/json) -- This is installed as a dependency by discordrb. Used for data storage.
