# EA OSD CLoud Demo Add-On
Write-Host "Starting EA OS-Deployment"
Start-Sleep -Seconds 5

#Uninstall-Module OSD -Force -AllVersions
#Install-Module OSD -Force
Import-Module OSD -Force

$Global:StartOSDCloudGUI = @{OSVersion = 'Windows 10'}
Start-OSDCloud -OSBuild 21H2 -OSLanguage en-us -OSEdition Enterprise -ZTI


# Create Install Folder
New-Item "C:\Install" -ItemType Directory -ErrorAction SilentlyContinue

# Create Install-CMD-File
$('@echo off') | Out-File -FilePath "C:\Install\01.Install.cmd" -Encoding utf8 -Force


# Download AnyDesk
    $OutFile = "C:\Install\slack.exe"
    $Source = "https://downloads.slack-edge.com/releases/windows/4.23.0/prod/x64/SlackSetup.exe"
    & curl.exe --location --output $OutFile --url $Source
# Add Install to CMD
    $('echo Installing Slack') | Out-File -FilePath "C:\Install\01.Install.cmd" -Encoding utf8 -Force -Append
    $('"%~dp0Slack.exe" --install "%ProgramFiles(x64)%\Slack" --start-with-win --silent --create-shortcuts --update-disabled') | Out-File -FilePath "C:\Install\01.Install.cmd" -Encoding utf8 -Force -Append
    $('echo AnyDesk Setup Errorocode: %ERRORLEVEL%') | Out-File -FilePath "C:\Install\01.Install.cmd" -Encoding utf8 -Force -Append
    $('TIMEOUT /T 5') | Out-File -FilePath "C:\Install\01.Install.cmd" -Encoding utf8 -Force -Append

        
# finish Install-CMD-File
    $('echo.') | Out-File -FilePath "C:\Install\01.Install.cmd" -Encoding utf8 -Force -Append


# Add Command to Unattend.xml
    $Panther = 'C:\Windows\Panther'
    $UnattendPath = "$Panther\Invoke-OSDSpecialize.xml"
    [XML]$Unattend = Get-Content -Path $UnattendPath

    $SpecializePass = $Unattend.unattend.settings | Where pass -eq "specialize"
    $WinDeployComponent = $SpecializePass.component | where name -eq "Microsoft-Windows-Deployment"

    $ExisitingRun = $WinDeployComponent.RunSynchronous.RunSynchronousCommand
    If ( $ExisitingRun.GetType().Name -eq "XmlElement" ) {
        $NewEntry = $ExisitingRun.CloneNode($true)
        $NewEntry.Order = [string]$([int]$($ExisitingRun | Sort Order -Descending).Order + 1).ToString()
    }
    ElseIf ( $ExisitingRun.GetType().BaseType.Name -eq "Array" ) {
        $NewEntry = $ExisitingRun[0].CloneNode($true)
        $NewEntry.Order = [string]$([int]$($ExisitingRun | Sort Order -Descending)[0].Order + 1).ToString()
    }
    $NewEntry.Description = "Run Custom Installs $($NewEntry.Order)"
    $NewEntry.Path = "cmd /c c:\Install\01.install.cmd"
    $WinDeployComponent.RunSynchronous.AppendChild($NewEntry)

    $NewUnattend = "C:\temp\OSDCloud\Customizations\unattend_1.xml"
    $Unattend.Save($UnattendPath)

# Customization finished

Write-Host "Finished OS Installation - Rebooting in 60 Seconds"
Start-Sleep -Seconds 60
wpeutil reboot
