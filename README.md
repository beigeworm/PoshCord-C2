# PoshCord-C2

**SYNOPSIS**

Using a Discord webhook and a hosted text file to Act as a Command and Control Platform.

**INFORMATION**

This script will wait until it notices a change in the contents of a text file hosted online (eg. github/pastebin).
Every 10 seconds it will check a file for a change in the file contents and interpret it as a custom command / module.

*Using github to host your command file will take up to 5 minutes to run each module command - Use pasatebin (account needed) your own server to host the txt file for instant response* 

**SETUP**
1. Goto https://pastebin.com and make an account..
2. create an empty paste/file and copy the RAW url.
3. change YOUR_FILE_URL to the RAW url  eg. https://pastebin.com/QeCLTdea -OR- http://your.server.ip.here/files/file.txt 
4. change YOUR_WEBHOOK_URL to your webhook eg. https://discord.com/api/webhooks/123445623531/f4fw3f4r46r44343t5gxxxxxx

**USAGE**

1. Setup the script
2. Run the script on a target.
3. Check discord for 'waiting to connect..' message.
4. Save the contents of your hosted file to contain 'options' to get a list of modules
5. Do the same with any other command listed - To run that module.

**MODULES**

= `Close`  : Close the Session                           =

= `Screenshot`  : Sends a screenshot of the desktop      =

= `Keycapture`   : Capture Keystrokes and send           =

= `Exfiltrate` : Send various files.                     =

= `Systeminfo` : Send System info as text file.          =

= `TakePicture` : Send a webcam picture.                 =

= `FolderTree` : Save folder trees to file and send.     =

= `FakeUpdate` : Spoof windows update screen.            =

= `CustomCommand` : Execute a github file as a script.   =

**EXTRA**

You can add custom scripting in a secondary hosted file, change YOUR_OTHER_GITHUB_FILE_URL to another text file and add code to it,
then in the original hosted file save it with 'customcommand' as the contents 

**Killswitch**

Save a hosted file contents as 'kill' to stop 'KeyCapture' or 'Exfiltrate' command and return to waiting for commands.
