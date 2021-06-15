# Script to setup golden image with Azure Image Builder

# Set global variables
$storageAccount = "aibstorscript1623209451"
$container = "aibfiles"
$filePath = "C:\AIBFiles"

# Create dir for source files on local machine
if (!(Test-Path $filePath)) {
    New-Item -Path "$filePath\Logs" -ItemType Directory -Force | Out-Null
}

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
$fileName = "GoogleChromeStandaloneEnterprise64.msi"
$blobUri = "https://$storageAccount.blob.core.windows.net/$container/$fileName"
$installFile = "$filePath\$fileName"
(New-Object System.Net.WebClient).DownloadFile($blobUri, $installFile)
$argList = '/i', $installFile, '/qn', '/norestart', "/l*v `"$filePath\Logs\Install-GoogleChromeEnterprise.log`""
Start-Process -FilePath msiexec.exe -ArgumentList $argList -PassThru -Verb "RunAs"
$installedName = "Google Chrome"
$isInstalled = CheckAppInstalled ($installedName)

# Check if app is installed
While ($isInstalled -ne $true) {
    Start-Sleep -Seconds 10
    # Check again if app is installed
    $isInstalled = CheckAppInstalled ($installedName)
}

# Install Citrix VDA
$fileName = "VDAServerSetup_2103.exe"
$blobUri = "https://$storageAccount.blob.core.windows.net/$container/$fileName"
$installFile = "$filePath\$fileName"
(New-Object System.Net.WebClient).DownloadFile($blobUri, $installFile)
$argList = '/components VDA', '/controllers "server1.domain server2.domain"', '/masterimage', '/noreboot', '/quiet', '/virtualmachine', '/enable_hdx_ports', '/enable_hdx_udp_ports', `
    '/enable_real_time_transport', '/enable_remote_assistance', '/exclude "Citrix Personalization for App-V - VDA"', "/logpath `"$filePath\Logs\Install-CitrixVDA.log`""
Invoke-Expression -Command "$installFile $argList"
$installedName = "Citrix Virtual Desktop Agent - x64"
$isInstalled = CheckAppInstalled ($installedName)

# Check if app is installed
While ($isInstalled -ne $true) {
    Start-Sleep -Seconds 10
    # Check again if app is installed
    $isInstalled = CheckAppInstalled ($installedName)
}

# Setup AU language packs
$fileName1 = "Microsoft-Windows-Client-Language-Pack_x64_en-gb.cab"
$fileName2 = "Microsoft-Windows-LanguageFeatures-Basic-en-au-Package~31bf3856ad364e35~amd64~~.cab"
$fileName3 = "Microsoft-Windows-LanguageFeatures-Handwriting-en-gb-Package~31bf3856ad364e35~amd64~~.cab"
$fileName4 = "Microsoft-Windows-LanguageFeatures-OCR-en-gb-Package~31bf3856ad364e35~amd64~~.cab"
$fileName5 = "Microsoft-Windows-LanguageFeatures-Speech-en-au-Package~31bf3856ad364e35~amd64~~.cab"
$fileName6 = "Microsoft-Windows-LanguageFeatures-TextToSpeech-en-au-Package~31bf3856ad364e35~amd64~~.cab"
$fileName7 = "Microsoft-Windows-Client-Language-Pack_x64_en-us.cab"
$fileName8 = "Microsoft-Windows-LanguageFeatures-Basic-en-us-Package~31bf3856ad364e35~amd64~~.cab"
$fileName9 = "Microsoft-Windows-LanguageFeatures-Handwriting-en-us-Package~31bf3856ad364e35~amd64~~.cab"

# Download .cab files
$blobUri = "https://$storageAccount.blob.core.windows.net/$container/$fileName1"
(New-Object System.Net.WebClient).DownloadFile($blobUri, "$filePath\$fileName1")
$blobUri = "https://$storageAccount.blob.core.windows.net/$container/$fileName2"
(New-Object System.Net.WebClient).DownloadFile($blobUri, "$filePath\$fileName2")
$blobUri = "https://$storageAccount.blob.core.windows.net/$container/$fileName3"
(New-Object System.Net.WebClient).DownloadFile($blobUri, "$filePath\$fileName3")
$blobUri = "https://$storageAccount.blob.core.windows.net/$container/$fileName4"
(New-Object System.Net.WebClient).DownloadFile($blobUri, "$filePath\$fileName4")
$blobUri = "https://$storageAccount.blob.core.windows.net/$container/$fileName5"
(New-Object System.Net.WebClient).DownloadFile($blobUri, "$filePath\$fileName5")
$blobUri = "https://$storageAccount.blob.core.windows.net/$container/$fileName6"
(New-Object System.Net.WebClient).DownloadFile($blobUri, "$filePath\$fileName6")
$blobUri = "https://$storageAccount.blob.core.windows.net/$container/$fileName7"
(New-Object System.Net.WebClient).DownloadFile($blobUri, "$filePath\$fileName7")
$blobUri = "https://$storageAccount.blob.core.windows.net/$container/$fileName8"
(New-Object System.Net.WebClient).DownloadFile($blobUri, "$filePath\$fileName8")
$blobUri = "https://$storageAccount.blob.core.windows.net/$container/$fileName9"
(New-Object System.Net.WebClient).DownloadFile($blobUri, "$filePath\$fileName9")

# Add AU langugage packs
Dism.exe /NoRestart /Online /Add-Package /PackagePath:$filePath\$fileName1 /LogPath:$filePath\Logs\Install-ClientLanguagePack.log /LogLevel:4
Dism.exe /NoRestart /Online /Add-Package /PackagePath:$filePath\$fileName2 /LogPath:$filePath\Logs\Install-BasicLanguagePack.log /LogLevel:4
Dism.exe /NoRestart /Online /Add-Package /PackagePath:$filePath\$fileName3 /LogPath:$filePath\Logs\Install-HandwritingLanguagePack.log /LogLevel:4
Dism.exe /NoRestart /Online /Add-Package /PackagePath:$filePath\$fileName4 /LogPath:$filePath\Logs\Install-OCRLanguagePack.log /LogLevel:4
Dism.exe /NoRestart /Online /Add-Package /PackagePath:$filePath\$fileName5 /LogPath:$filePath\Logs\Install-SpeechLanguagePack.log /LogLevel:4
Dism.exe /NoRestart /Online /Add-Package /PackagePath:$filePath\$fileName6 /LogPath:$filePath\Logs\Install-TextToSpeechLanguagePack.log /LogLevel:4

# Remove US language packs
Dism.exe /NoRestart /Online /Remove-Package /PackagePath:$filePath\$fileName7 /LogPath:$filePath\Logs\Remove-USClientLanguagePack.log /LogLevel:4
Dism.exe /NoRestart /Online /Remove-Package /PackagePath:$filePath\$fileName8 /LogPath:$filePath\Logs\Remove-USBasicLanguagePack.log /LogLevel:4
Dism.exe /NoRestart /Online /Remove-Package /PackagePath:$filePath\$fileName9 /LogPath:$filePath\Logs\Remove-USHandWritingRLanguagePack.log /LogLevel:4

# Set machine locale and time zone
$str = @'
<?xml version="1.0"?>

-<gs:GlobalizationServices xmlns:gs="urn:longhornGlobalizationUnattend">

<!--User List-->

-<gs:UserList>

<gs:User CopySettingsToSystemAcct="true" CopySettingsToDefaultUserAcct="true" UserID="Current"/>

</gs:UserList>

<!-- user locale -->

-<gs:UserLocale>

<gs:Locale SetAsCurrent="true" Name="en-AU"/>

</gs:UserLocale>

<!-- system locale -->

<gs:SystemLocale Name="en-AU"/>

<!-- GeoID -->

-<gs:LocationPreferences>

<gs:GeoID Value="12"/>

</gs:LocationPreferences>

-<gs:MUILanguagePreferences>

<gs:MUILanguage Value="en-AU"/>

<gs:MUIFallback Value="en-US"/>

</gs:MUILanguagePreferences>

<!-- input preferences -->

-<gs:InputPreferences>

<!--en-AU-->

<gs:InputLanguageID Default="true" ID="0c09:00000409" Action="add"/>

</gs:InputPreferences>

</gs:GlobalizationServices>
'@

$xml = $ExecutionContext.InvokeCommand.ExpandString($str)

# Set Locale, language etc. 
& $env:SystemRoot\System32\control.exe "intl.cpl,,/f:`"$xml`""

# Set languages/culture. Not needed perse.
Set-WinSystemLocale en-AU
Set-WinUserLanguageList -LanguageList en-AU -Force
Set-Culture -CultureInfo en-AU
Set-WinHomeLocation -GeoId 12
# Set-TimeZone -Name "AUS Eastern Standard Time"
tzutil.exe /s "AUS Eastern Standard Time"

# Remove AppX packages
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
    Get-AppxPackage -Name $ProvisionedAppName -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayName -EQ $ProvisionedAppName | Remove-AppxProvisionedPackage -Online
}

# Optimise OS using Citrix Optimizer
$appName = "CitrixOptimizer"
$URI = "https://$storageAccount.blob.core.windows.net/$container/$appName.zip"
Invoke-WebRequest -Uri $URI -OutFile "$filePath\$appName.zip"
Expand-Archive -Path "$filePath\$appName.zip" -DestinationPath "$filePath\$appName" -Force
$installFile = "$filePath\$appName\CtxOptimizerEngine.ps1"

Invoke-Expression -Command "powershell.exe -ExecutionPolicy Bypass -File $installFile -Source Citrix_Windows_10_2009.xml -Mode Execute"

# Add VM parameter to Azure Sysprep script - this prevents the first login from hanging on "Windows Modules Installer"
((Get-Content -path C:\DeprovisioningScript.ps1 -Raw) -replace 'Sysprep.exe /oobe /generalize /quiet /quit', 'Sysprep.exe /oobe /generalize /quit /mode:vm' ) `
| Set-Content -Path C:\DeprovisioningScript.ps1
