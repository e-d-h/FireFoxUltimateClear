<#
Firefox ultimate clear 1.0 - by E-D-H

This script will clear firefox ultimately (No ff refresh needed) and only 
places the settings that are defined in an external file: configureFF.txt
These are just a copy of the relevant items from the .js file that stores
all settings (also tweakable by about:config), for example

user_pref("accessibility.force_disabled", 1);
user_pref("app.update.service.enabled", false);
user_pref("browser.discovery.enabled", false);
user_pref("browser.download.animateNotifications", false);
user_pref("browser.download.dir", "D:\\ffdownloads");
user_pref("browser.download.folderList", 2);
user_pref("browser.download.lastDir", "D:\\ffdownloads");
user_pref("browser.download.panel.shown", true);
user_pref("browser.ping-centre.telemetry", false);
user_pref("browser.startup.homepage", "https://www.google.com");

Advice: copy them as text directly from the configured prefs.js file! (Author uses 60 entries...)
#>

$curDir = $PSScriptRoot

if ($curDir -eq '' -and $null -ne $psISE) 
    {
    # Fill for ISE development
    $curDir = Split-Path -Path $psISE.CurrentFile.FullPath
    Set-Location $curDir
    }
if ($curDir -eq '' -and $null -ne $psEditor)
    {
    # Fill for VSCode development
    $curDir  = Split-Path -Path $psEditor.GetEditorContext().CurrentFile.path
    Set-Location $curDir    
    }

$firefoxExe = "C:\Program Files\Mozilla Firefox\firefox.exe"
$helperExe  = "C:\Program Files\Mozilla Firefox\uninstall\helper.exe"
$ffPath = Split-Path -Path $firefoxExe

# Kill firefox if running

if ($null -ne (Get-Process -Name "Firefox" -ErrorAction SilentlyContinue))
    {
    Write-Host "Firefox is running, killing it" -ForegroundColor Green
    Stop-Process -Name "Firefox" -Force
    }

# Deinstall if it is there

if (Test-Path $helperExe)
    {
    Write-Host "Uninstalling old version" -ForegroundColor Green
    Start-Process -FilePath $helperExe -ArgumentList "/s" -Wait
    }
# Remove leftover trash, to be sure first restart Explorer for locked processes
if (Test-Path $ffPath)
    {
    Stop-Process -Name "Explorer"
    Remove-Item -Path $ffPath -Recurse -Force
    }

# Download latest firefox
Add-Type -AssemblyName System.Web
$realUrlEnc = (Invoke-WebRequest -uri "https://download.mozilla.org/?product=firefox-msi-latest-ssl&os=win64&lang=en-US" -Method Head).BaseResponse.responseUri.OriginalString
$realUrl = [System.Web.HttpUtility]::UrlDecode($realUrlEnc)
$fileName = ($realUrl -split "/")[-1]
Write-Host "Found latest firefox at url: $realUrl" -ForegroundColor Green

if (Test-Path $curDir\$fileName)
    {
    Write-Host "File $fileName already available" -ForegroundColor Green
    }
else
    {
    Invoke-WebRequest -uri $realUrl -OutFile $curDir\$fileName
    }


Write-Host "Installing firefox $fileName..." -ForegroundColor Green
 
Start-Process -FilePath "c:\windows\system32\msiexec.exe" -ArgumentList "/i `"$curDir\$fileName`" INSTALL_MAINTENANCE_SERVICE=false START_MENU_SHORTCUT=false /qb-!" -Wait

if (!(test-path $curDir\configureFF.txt))
    {
    Write-Host "No configuration file found"
    Break  
    }
$ffSettings = (Get-Content $curDir\configureFF.txt)|Where-Object {$_ -ne ''}
if ($null -eq $ffSettings)
    {
    Write-Host "Configuration file is empty"
    Break
    }

Write-Host "Clearing Both local and roaming Firefox appdata folders" -ForegroundColor Green

Remove-Item -Path "$env:APPDATA\Mozilla\Firefox\*" -Recurse -Force
Remove-Item -Path "$env:LOCALAPPDATA\Mozilla\Firefox\*" -Recurse -Force

Start-Process -FilePath $firefoxExe -ArgumentList "-headless"
Write-Host "Firefox silently started to create some default files" -ForegroundColor Green

Start-Sleep 5

Stop-Process -Name "Firefox" -Force
Write-Host "Firefox killed, configuration prefs.js will be placed..."
Write-Host "Red is the old value, Green is the new value, yellow means it was not in the file"

$jsFile = Get-ChildItem -Path "$env:APPDATA\Mozilla\Firefox" -Recurse -Filter "prefs.js"
$jsContent = (Get-Content -Path $jsFile.FullName) 

ForEach ($ffSetting in $ffSettings)
   {
   $ffSettingLeft = ($ffSetting -split ",")[0]
   $matchedLine = $jsContent -match [regex]::escape($ffSettingLeft)

   if ($matchedLine.count -ne 0)
      {
       # Replace the line in config 
      $i = [array]::IndexOf($jsContent,$matchedLine)
      if ($jsContent[$i] -ne $ffSetting)
         {
         Write-Host $jsContent[$i] -ForegroundColor Red
         $jsContent[$i] = $ffSetting
         Write-Host $jsContent[$i] -ForegroundColor Green
         }
      }
   else 
      {
      # Add the line in config
      $jsContent += $ffSetting
      Write-Host $ffSetting -ForegroundColor Yellow
      }
   }

#clear stuff again
Write-Host "Clearing all firefox data folders again" -ForegroundColor Green

Remove-Item -Path "$env:LOCALAPPDATA\Mozilla\Firefox\*" -Recurse -Force
Remove-Item -Path "$env:APPDATA\Mozilla\Firefox\Crash Reports" -Recurse -Force -ErrorAction SilentlyContinue

$profilePath = $jsFile.DirectoryName

Remove-Item -Path "$profilePath\*" -Recurse -Force
 
$jsonFile = "$profilePath\xulstore.json"
$jsonContent = '{"chrome://browser/content/browser.xhtml":{"main-window":{"screenX":20,"screenY":"20","width":1880,"height":1020,"sizemode":"maximized"}}}' 
$jsonContent|Out-File $jsonFile -Encoding ascii
($jsContent -notmatch "^//"|Sort-Object)|out-file -FilePath $jsFile.FullName -Encoding ascii

Write-Host "File xulstore.json is created with a default and prefs.js is placed"
Start-Sleep 10
