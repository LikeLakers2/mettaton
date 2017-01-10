screen -dmSL wikibot-echo echo "****NEW SESSION STARTED (StillAlive)***"
sleep 1
screen -dmSL wikibot-echo-date date +" %m/%d/%Y %H:%M:%S $HOSTNAME"
sleep 1
screen -dmSL wikibot ruby run.rb