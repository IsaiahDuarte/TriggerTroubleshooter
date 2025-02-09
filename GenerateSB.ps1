$releaseFolder = Join-Path -Path $PSScriptRoot -ChildPath "Release"
$sbBase = Join-Path -Path $PSScriptRoot -ChildPath "sb_base.ps1"
$moduleFolder = Join-Path -Path $PSScriptRoot -ChildPath "TriggerTroubleshooter"
$moduleZip = Join-Path -Path $PSScriptRoot -ChildPath "Release\TriggerTroubleshooter.zip"
$targetScript = Join-Path $PSScriptRoot -ChildPath "Release\ScriptAction.ps1"
$sbBasexml = Join-Path -Path $PSScriptRoot -ChildPath "sb_base.xml"
$sbTargetXML = Join-Path -Path $PSScriptRoot -ChildPath "Release\Trigger Troubleshooter.xml"
$moduleManifest = Join-Path -Path $PSScriptRoot -ChildPath "TriggerTroubleshooter\TriggerTroubleshooter.psd1"
$marker = "###ImportModule###"

if(!(Test-Path -Path $releaseFolder)) {
    New-Item -ItemType Directory -Path $releaseFolder | Out-Null
}

# Build script
$functions = Get-ChildItem -Path $moduleFolder -Filter *.ps1 -Recurse
$functionsCode = [System.Collections.Generic.List[string]]::New()
foreach($file in $functions) {
    [void] $functionsCode.Add("`n`n#region $($file.Name)`n`n")
    $codeBlock = Get-Content $file.FullName -Raw
    [void] $functionsCode.Add($codeBlock)
    [void] $functionsCode.Add("`n`n#endregion`n`n")
}
$functionsCodeblock = [string]::Join("",$functionsCode.ToArray())
$sbBaseContent = Get-Content -Path $sbBase -Raw
if(-not $sbBaseContent.Contains($marker)) {
    Write-Error "The marker '$marker' was not founf in $sbBase"
    exit
}
$parts = $sbBaseContent -split [regex]::Escape($marker)
if($parts.Count -ne 2) {
    Write-Error "Unable to split $sbBase"
    exit
}
$updatedContent = $parts[0] + $marker + "`n" + $functionsCodeblock + "`n" + $parts[1]
Set-Content -Path $targetScript -Value $updatedContent -Encoding UTF8

# Build XML
$manifest = Import-PowerShellDataFile -Path $moduleManifest
[xml] $sbXML = Get-Content -Path $sbBasexml -Raw
$sbXML.ArrayOfSBADescriptor.SBADescriptor.Version = $manifest.ModuleVersion

# Compresss and encode script
$scriptBytes = [System.Text.Encoding]::Unicode.GetBytes((Get-Content -Path $targetScript -Raw))
$compressedStream = [System.IO.MemoryStream]::New()
$gZipStream = [System.IO.Compression.GZipStream]::New($compressedStream, [System.IO.Compression.CompressionMode]::Compress)
$gZipStream.Write($scriptBytes, 0, $scriptBytes.Length)
$gZipStream.Close()
$compressedBytes = $compressedStream.ToArray()
$sbXML.ArrayOfSBADescriptor.SBADescriptor.ExecutionDescriptor.ScriptData = [System.Convert]::ToBase64String($compressedBytes)

# Date Modified
$sbXML.ArrayOfSBADescriptor.SBADescriptor.DateModified = [datetime]::Now.ToString("o")

$sbXML.Save($sbTargetXML)

# Compress module to zip
Compress-Archive -Path $moduleFolder -DestinationPath $moduleZip -Force