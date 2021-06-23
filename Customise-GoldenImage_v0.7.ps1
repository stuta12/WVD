# Script to setup golden image with Azure Image Builder

# Set global variables
$storageAccount = "aibstorscript1623209451"
$container = "aibfiles"
$filePath = "C:\AIBFiles"
$logFile = "C:\AIBFiles\Logs\Customise-GoldenImage.log"
$scriptVersion = 0.7

# Create dir for source files on local machine
if (!(Test-Path $filePath)) {
    New-Item -Path "$filePath\Logs" -ItemType Directory -Force | Out-Null
}

# Create function for custom logging
Function WriteLog {
    Param ([string]$logString)
    Add-content $logFile -value $logString
}

WriteLog "Starting script Customise-GoldenImage.ps1"
WriteLog "Script version: $scriptVersion"
WriteLog ""

# Function to check if app is installed before continuing script
Function CheckAppInstalled ($programName) {
    $WMICheck = (Get-WMIObject -Query "SELECT * FROM Win32_Product Where Name Like '%$programName%'")
    if (!([string]::IsNullOrEmpty($WMICheck))) {
        return $true
    }
    else {
        return $false
    }
}

# Install Google Chrome Enterprise
WriteLog "Installing Google Chrome Enterprise"
$fileName = "GoogleChromeStandaloneEnterprise64.msi"
$blobUri = "https://$storageAccount.blob.core.windows.net/$container/$fileName"
$installFile = "$filePath\$fileName"
WriteLog "Downloading file $blobUri"
(New-Object System.Net.WebClient).DownloadFile($blobUri, $installFile)
$argList = '/i', $installFile, '/qn', '/norestart', "/l*v `"$filePath\Logs\Install-GoogleChromeEnterprise.log`""
WriteLog "Executing command: Start-Process -FilePath msiexec.exe -ArgumentList $argList -PassThru -Verb RunAs"
Start-Process -FilePath msiexec.exe -ArgumentList $argList -PassThru -Verb "RunAs"
$installedName = "Google Chrome"
$isInstalled = CheckAppInstalled ($installedName)

# Check if app is installed
While ($isInstalled -ne $true) {
    Start-Sleep -Seconds 10
    WriteLog "Checking if $installedName is installed"
    # Check again if app is installed
    $isInstalled = CheckAppInstalled ($installedName)
}

WriteLog "$installedName installed"
WriteLog ""

# Install Citrix VDA
WriteLog "Installing Citrix VDA"
$fileName = "VDAServerSetup_2103.exe"
$blobUri = "https://$storageAccount.blob.core.windows.net/$container/$fileName"
$installFile = "$filePath\$fileName"
WriteLog "Downloading file $blobUri"
(New-Object System.Net.WebClient).DownloadFile($blobUri, $installFile)
$argList = '/components VDA', '/controllers "server1.domain server2.domain"', '/masterimage', '/noreboot', '/quiet', '/virtualmachine', '/enable_hdx_ports', '/enable_hdx_udp_ports', `
    '/enable_real_time_transport', '/enable_remote_assistance', '/exclude "Citrix Personalization for App-V - VDA"', "/logpath `"$filePath\Logs\Install-CitrixVDA.log`""
WriteLog "Executing command: Invoke-Expression -Command $installFile $argList"
Invoke-Expression -Command "$installFile $argList"
$installedName = "Citrix Virtual Desktop Agent - x64"
$isInstalled = CheckAppInstalled ($installedName)

# Check if app is installed
While ($isInstalled -ne $true) {
    Start-Sleep -Seconds 10
    WriteLog "Checking if $installedName is installed"
    # Check again if app is installed
    $isInstalled = CheckAppInstalled ($installedName)
}

WriteLog "$installedName installed"
WriteLog ""

# Remove AppX packages
WriteLog "Removing AppX packages"
$ProvisionedAppPackageNames = @(
    "Microsoft.Messaging"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.MixedReality.Portal"
    "Microsoft.OneConnect"
    "Microsoft.People"
    "Microsoft.Print3D"
    "Microsoft.SkypeApp"
    "Microsoft.Wallet"
    "Microsoft.WindowsAlarms"
    "microsoft.windowscommunicationsapps"
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.WindowsMaps"
    "Microsoft.WindowsSoundRecorder"
    "Microsoft.Xbox.TCUI"
    "Microsoft.XboxApp"
    "Microsoft.XboxGameOverlay"
    "Microsoft.XboxGamingOverlay"
    "Microsoft.XboxIdentityProvider"
    "Microsoft.XboxSpeechToTextOverlay"
    "Microsoft.YourPhone"
    "Microsoft.ZuneMusic"
    "Microsoft.ZuneVideo"
    "Microsoft.BingWeather"
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"
)
 
foreach ($ProvisionedAppName in $ProvisionedAppPackageNames) {
    WriteLog "Removing $ProvisionedAppName"
    Get-AppxPackage -Name $ProvisionedAppName -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayName -EQ $ProvisionedAppName | Remove-AppxProvisionedPackage -Online
}

WriteLog ""

# Remove OneDrive
WriteLog "Removing OneDrive"
reg.exe load HKU\Temphive "C:\Users\Default\NTUSER.DAT"
reg delete "HKU\Temphive\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v OneDriveSetup /f
reg.exe unload HKU\Temphive
WriteLog ""

# Optimise OS using Citrix Optimizer
WriteLog "Run Citrix OS Optimiser"
$appName = "CitrixOptimizer"
$URI = "https://$storageAccount.blob.core.windows.net/$container/$appName.zip"
WriteLog "Downloading file: $URI"
Invoke-WebRequest -Uri $URI -OutFile "$filePath\$appName.zip"
Expand-Archive -Path "$filePath\$appName.zip" -DestinationPath "$filePath\$appName" -Force
$installFile = "$filePath\$appName\CtxOptimizerEngine.ps1"

WriteLog "Executing command: powershell.exe -ExecutionPolicy Bypass -File $installFile -Source Citrix_Windows_10_2009.xml -Mode Execute"
Invoke-Expression -Command "powershell.exe -ExecutionPolicy Bypass -File $installFile -Source Citrix_Windows_10_2009.xml -Mode Execute"
WriteLog ""

# Import custom start menu and taskbar layout
WriteLog "Import custom start menu and taskbar"
$fileName = "PUDStartLayout.xml"
$blobUri = "https://$storageAccount.blob.core.windows.net/$container/$fileName"
WriteLog "Downloading file: $blobUri"
(New-Object System.Net.WebClient).DownloadFile($blobUri, "$filePath\$fileName")
WriteLog "Executing command: Remove-Item -Path $env:SystemDrive\Users\Default\AppData\Local\Microsoft\Windows\Shell\* -Force"
Remove-Item -Path "$env:SystemDrive\Users\Default\AppData\Local\Microsoft\Windows\Shell\*" -Force
WriteLog "Executing command: Import-StartLayout -LayoutPath $filePath\$fileName -MountPath C:\"
Import-StartLayout -LayoutPath "$filePath\$fileName" -MountPath C:\
WriteLog ""

# Add VM parameter to Azure Sysprep script - this prevents the first login from hanging on "Windows Modules Installer"
WriteLog "Update provisioning script with sysprep command"
WriteLog "Replacing: Sysprep.exe /oobe /generalize /quiet /quit with: Sysprep.exe /oobe /generalize /quit /mode:vm in C:\DeprovisioningScript.ps1"
((Get-Content -path C:\DeprovisioningScript.ps1 -Raw) -replace 'Sysprep.exe /oobe /generalize /quiet /quit', 'Sysprep.exe /oobe /generalize /quit /mode:vm' ) `
| Set-Content -Path C:\DeprovisioningScript.ps1

# Remove IE11
$InstallStatus = (Get-WindowsOptionalFeature -FeatureName Internet-Explorer-Optional-amd64 –Online)

If ($InstallStatus.state -eq 'Enabled') {
    # Note that the removal requires a reboot
    Disable-WindowsOptionalFeature -FeatureName Internet-Explorer-Optional-amd64 –Online -NoRestart
}

WriteLog ""
WriteLog "Script finished, exiting"
