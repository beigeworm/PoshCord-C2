# PoshCord-C2

**SYNOPSIS**

Using a Discord webhook and a hosted text file to Act as a Command and Control Platform.

**INFORMATION**

This script will wait until it notices a change in the contents of a text file hosted online (eg. github/pastebin).
Every 10 seconds it will check a file for a change in the file contents and interpret it as a custom command / module.

*Using github to host your command file will take up to 5 minutes to run each module command - Use pastebin (account needed) OR your own server to host the txt file for instant response* 

**SETUP**
1. Goto https://pastebin.com and make an account..
2. Create an empty paste/file and copy the RAW url.
3. Change YOUR_FILE_URL to the RAW url  eg. https://pastebin.com/QeCLTdea -OR- http://your.server.ip.here/files/file.txt 
4. Change YOUR_WEBHOOK_URL to your webhook eg. https://discord.com/api/webhooks/123445623531/f4fw3f4r46r44343t5gxxxxxx

**USAGE**
1. Setup the script
2. Run the script on a target.
3. Check discord for 'waiting to connect..' message.
4. Edit the contents of your hosted file to contain 'options' to get a list of modules
5. Do the same with any other command listed - To run that module.

**MODULES**
1. `Message` : Send a message window to the Users desktop.          
2. `Screenshot`  : Sends a screenshot of the desktop to Discord.      
3. `KeyCapture`   : Capture Keystrokes and send to Discord. (see ExtraInfo for usage.)          
4. `Exfiltrate` : Send various files to Discord zipped in 25mb files. (see ExtraInfo for usage.)                   
5. `Upload` : Upload a file to Discord. (see ExtraInfo for usage.)     
6. `Systeminfo` : Send System information as text file to Discord. (takes a few minutes to gather data)         
7. `TakePicture` : Send a webcam picture to Discord. (can take a few minutes..)
8. `FolderTree` : Save folder trees to file and send to Discord.
9. `FakeUpdate` : Spoof windows update screen.            
10. `AddPersistance` : Add this script to the startup folder.         
11. `RemovePersistance` : Remove this script from the startup folder.              
12. `CustomCommand` : Execute a hosted text file as a script. 
13. `IsAdmin`  : Check if the session is admin.             
14. `AttemptElevate` : Attempt to restart script as admin. (displays a UAC prompt to User)  
15. `EnumerateLAN`  : Show all devices on the network (see ExtraInfo for usage.) (can take a few miniutes to complete)    
16. `Close`  : Close this Session                          
17. `Options`  : Show the Module menu
18. `ExtraInfo`  : Show extra Module information

**FEATURES**

**Custom Script**

You can add custom scripting in a secondary hosted file, change YOUR_OTHER_FILE_URL to another text file and add code to it,
then in the original hosted file save it with 'customcommand' as the contents 

**Killswitch**

Save a hosted file contents as 'kill' to stop 'KeyCapture' or 'Exfiltrate' command and return to waiting for commands.

# If you like my work please leave a star. ⭐
