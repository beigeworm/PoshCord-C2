# PoshCord-C2

**SYNOPSIS**

Using a Discord webhook and a hosted text file to Act as a Command and Control Platform.

**INFORMATION**

This script will wait until it notices a change in the contents of a text file hosted online (eg. github/pastebin).
Every 10 seconds it will check a file for a change in the file contents and interpret it as a custom command / module.

*Using github to host your command file will take up to 5 minutes to run each module command - Use pastebin (account needed) OR your own server to host the txt file for instant response* 

(Using .vbs stager and python bot)

![GIF 3-6-2024 9-01-04 PM](https://github.com/beigeworm/PoshCord-C2/assets/93350544/a741facf-ed46-4d0d-b68f-df6bdf5da8c1)

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
2. `SpeechToText`  : Send microphone audio transcript to Discord       
3. `Screenshot`  : Sends a screenshot of the desktop to Discord.      
4. `KeyCapture`   : Capture Keystrokes and send to Discord. (see ExtraInfo for usage.)          
5. `Exfiltrate` : Send various files to Discord zipped in 25mb files. (see ExtraInfo for usage.)                   
6. `Upload` : Upload a file to Discord. (see ExtraInfo for usage.)     
7. `Systeminfo` : Send System information as text file to Discord. (takes a few minutes to gather data)
8. `RecordAudio`  : Record microphone to Discord (RecordAudio -t 100) in seconds
9. `RecordScreen`  : Record Screen to Discord (RecordScreen -t 100) in seconds
10. `TakePicture` : Send a webcam picture to Discord. (can take a few minutes..)
11. `FolderTree` : Save folder trees to file and send to Discord.
12. `FakeUpdate` : Spoof windows update screen.
13. `Nearby-Wifi` : Show nearby wifi networks
14. `Send-Hydra` : Never ending popups (use killswitch)            
15. `AddPersistance` : Add this script to the startup folder.         
16. `RemovePersistance` : Remove this script from the startup folder.               
17. `IsAdmin`  : Check if the session is admin.             
18. `AttemptElevate` : Attempt to restart script as admin. (displays a UAC prompt to User)  
19. `EnumerateLAN`  : Show all devices on the network (see ExtraInfo for usage.) (can take a few miniutes to complete)    
20. `Close`  : Close this Session                          
21. `Options`  : Show the Module menu
22. `ExtraInfo`  : Show extra Module information


**FEATURES**

**Custom Scripting**

Edit the hosted file contents to any custom powershell script or command to run custom powershell.

**Killswitch**

Save a hosted file contents as 'kill' to stop 'KeyCapture' or 'Exfiltrate' command and return to waiting for commands.

# If you like my work please leave a star. ⭐
