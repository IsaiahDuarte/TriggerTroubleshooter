param (
    [Parameter(Mandatory)]
    [string]$TriggerName,

    [Parameter()]
    [ValidateSet("False", "True")]
    [string]$UseExport = "False",

    [Parameter()]
    [ValidateSet("False", "True")]
    [string]$CollectSupportZip = "False",

    [Parameter()]
    [int]$RecordsPerFolder = 100
)

if ($UseExport -eq "True" -and $PSBoundParameters.ContainsKey("RecordsPerFolder")) {
    Write-Verbose "The 'RecordsPerFolder' value will be ignored because 'UseExport' is set to True."
}

function Get-GitPath {
    param(
        [string]$URL = 'https://api.github.com/repos/IsaiahDuarte/TriggerTroubleshooter/releases/latest'
    )
    $LatestVersion = Invoke-WebRequest -Uri $URL -UseBasicParsing | Select-Object -ExpandProperty Content | ConvertFrom-Json
    return ($LatestVersion.Assets | Where-Object { $_.Name -eq 'TriggerTroubleshooter.zip' }).browser_download_url
}

function Get-TriggerTroubleshooter {
    param(
        [string]$GitPath,
        [string]$DestinationPath
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

# Download and import TriggerTroubleshooter
$path = Get-TriggerTroubleshooter -GitPath (Get-GitPath) -DestinationPath $ENV:TEMP
Write-Host "Importing TriggerTroubleshooter module"
Import-Module $path

Write-Host "`nTesting trigger: $TriggerName"
if ($UseExport -eq "True") {
    Write-Verbose "Using Export logic."
    $result = Test-Trigger -Name $TriggerName -UseExport $true
}
else {
    Write-Verbose "Using Query logic with RecordsPerFolder = $RecordsPerFolder."
    $result = Test-Trigger -Name $TriggerName -RecordsPerFolder $RecordsPerFolder
}

if ($null -ne $result) {
    Write-Host "`nTested $($result.count) records against trigger conditions"
    $result.DisplayResult()
}

if ($CollectSupportZip -eq "True") {
    Write-Host "Collecting Support Dump"
    Get-SupportTriggerDump -Name $TriggerName
}