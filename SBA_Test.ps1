param (
    [Parameter(Mandatory)]
    [string] $TriggerName,

    [Parameter(Mandatory=$false)]
    [ValidateSet("False","True")]
    [string] $UseExport,

    [Parameter(Mandatory=$false)]
    [ValidateSet("False","True")]
    [string] $CollectSupportZip
)
function Get-GitPath {
    param(
        [string] $URL = 'https://api.github.com/repos/IsaiahDuarte/TriggerTroubleshooter/releases/latest' 
    )

    $LatestVersion = Invoke-WebRequest -Uri $URL -UseBasicParsing | Select-Object -ExpandProperty Content | ConvertFrom-Json 
    return ($LatestVersion.Assets | Where-Object {$_.Name -eq 'TriggerTroubleshooter.zip'}).browser_download_url
}

function Get-TriggerTroubleshooter {
    param(
        [string] $GitPath,
        [string] $DestinationPath
    )

    try {
        $zipPath = Join-Path $DestinationPath "TriggerTroubleshooter.zip"
        $folderPath = Join-Path -Path $DestinationPath -ChildPath "TriggerTroubleshooter"
        Invoke-WebRequest -Uri $GitPath -OutFile $zipPath -UseBasicParsing

        Unblock-File $zipPath

        Expand-Archive -Path $zipPath -DestinationPath $folderPath -Force
        Remove-Item -Path $zipPath -Force

        $modulePath = Get-ChildItem -Path $folderPath -Filter "TriggerTroubleshooter.psd1" -Recurse | Select-Object -First 1 -ExpandProperty FullName
        return $modulePath
    }
    catch {
        Write-Error "Failed to download or extract TriggerTroubleshooter: $_"
        exit 1
    }
}

Write-Host "Importing latest module from monitor"
$pathToUserModule = (Get-ChildItem "C:\Program Files\Smart-X\ControlUpMonitor\*ControlUp.PowerShell.User.dll" -Recurse | Sort-Object LastWriteTime -Descending)[0]
Import-Module $pathToUserModule

$path = Get-TriggerTroubleshooter -GitPath (Get-GitPath) -DestinationPath $ENV:TEMP
Write-host "Importing TriggerTroubleshooter module"
Import-Module $path

Write-Host "`nTesting $TriggerName"
$result = Test-Trigger -Name $TriggerName -UseExport ($UseExport -eq "True")

if($null -ne $result) {
    Write-Host "`nTested $($result.count) recrods against trigger conditions"
    $result.DisplayResult()
}
if($CollectSupportZip -eq "True") {
    Write-Host "Collecting Support Dump"
    Get-SupportTriggerDump -Name $TriggerName
}
