# Script to setup golden image with Azure Image Builder

# Create dir for source files
$filePath = "C:\AIBFiles"
if (!(Test-Path $filePath))
{
    New-Item -Path $filePath -ItemType Directory -Force | Out-Null
}

# Install Google Chrome Enterprise
$appName = "GoogleChromeEnterprise"
$URI = "https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B0FAA6D8C-0109-84FD-D741-1390BD720A45%7D%26lang%3Den%26browser%3D4%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dtrue%26ap%3Dx64-stable-statsdef_0%26brand%3DGCEB/dl/chrome/install/GoogleChromeEnterpriseBundle64.zip"
Invoke-WebRequest -Uri $URI -OutFile "$filePath\$appName.zip"
Expand-Archive -Path "$filePath\$appName.zip" -DestinationPath "$filePath\$appName" -Force
$installFile = "$filePath\$appName\Installers\GoogleChromeStandaloneEnterprise64.msi"
$argList = '/i', $installFile, '/qn', '/norestart'
Start-Process -FilePath msiexec.exe -ArgumentList $argList -PassThru -Verb "RunAs"
