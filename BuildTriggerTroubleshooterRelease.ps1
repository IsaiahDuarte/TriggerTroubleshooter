<#
    .SYNOPSIS
       Builds the release package for the TriggerTroubleshooter module.

    .DESCRIPTION
       This script collects all function files from the TriggerTroubleshooter module,
       injects them into a base script (sb_base.ps1) at the designated marker, updates
       an XML descriptor with the module version, compresses the updated script into a
       Base64 encoded GZip stream, and finally compresses the entire module into a zip file.

    .NOTES
        Version:           1.0.0
        Author:            Isaiah Duarte
        Creation Date:     2/9/2025
        Updated:           2/9/2025
        Context:           This script was made to package TriggerTroubleshooter
#>

#region Initialization

# Define paths relative to the current script location.
$releaseFolder = Join-Path -Path $PSScriptRoot -ChildPath "Release"
$sbBase = Join-Path -Path $PSScriptRoot -ChildPath "sb_base.ps1"
$moduleFolder = Join-Path -Path $PSScriptRoot -ChildPath "src"
$moduleZip = Join-Path -Path $PSScriptRoot -ChildPath "Release\TriggerTroubleshooter.zip"
$targetScript = Join-Path -Path $PSScriptRoot -ChildPath "Release\ScriptAction.ps1"
$sbBasexml = Join-Path -Path $PSScriptRoot -ChildPath "sb_base.xml"
$sbTargetXML = Join-Path -Path $PSScriptRoot -ChildPath "Release\Trigger Troubleshooter.xml"
$moduleManifest = Join-Path -Path $PSScriptRoot -ChildPath "src\TriggerTroubleshooter.psd1"
$integrationTestPath = Join-Path -Path $PSScriptRoot -ChildPath "tests\integration\Public\Test-Trigger.ps1"
$marker = "###ImportModule###"

# Ensure the release folder exists.
if (-not (Test-Path -Path $releaseFolder)) {
    Write-Verbose "Release folder not found. Creating folder at $releaseFolder"
    New-Item -ItemType Directory -Path $releaseFolder | Out-Null
}

#endregion

#region Unit Tests
$testResult = Invoke-Pester -PassThru 
if($testResult.TotalCount -eq $testResult.PassedCount) {
    Write-Host "Unit tests passed"
} else {
    exit 1
}
#endregion

#region Integration Tests
$testResult = "Invoke-Pester -Path '$integrationTestPath'" | powershell.exe -NoProfile -NonInteractive -NoLogo -ExecutionPolicy Bypass -Command -
$testResult
if([Regex]::Match($testResult[-1],"Failed: 0").Success) {
    Write-Host "Integration tests passed"
} else {
    exit 1
}
#endregion

#region Build Script

Write-Output "Collecting module functions from $moduleFolder"

# Get all .ps1 files from the module folder.
$functions = Get-ChildItem -Path $moduleFolder -Filter *.ps1 -Recurse

# Build the code block to be injected into the sb_base.
$functionsCode = New-Object 'System.Collections.Generic.List[string]'
foreach ($file in $functions) {
    $header = "`n`n#region $($file.Name)`n"
    $footer = "`n#endregion`n`n"
    $codeBlock = Get-Content -Path $file.FullName -Raw

    $functionsCode.Add($header)
    $functionsCode.Add($codeBlock)
    $functionsCode.Add($footer)
}

$functionsCodeblock = [string]::Join("", $functionsCode)

# Read the base script content.
if (-not (Test-Path -Path $sbBase)) {
    Write-Error "Base script not found at $sbBase"
    exit
}

$sbBaseContent = Get-Content -Path $sbBase -Raw

# Verify that the marker exists in the base script.
if (-not $sbBaseContent.Contains($marker)) {
    Write-Error "The marker '$marker' was not found in $sbBase"
    exit
}

# Split sb_base content on the marker.
$parts = $sbBaseContent -split [regex]::Escape($marker)
if ($parts.Count -ne 2) {
    Write-Error "Unable to split $sbBase using the marker."
    exit
}

# Build the updated script content by inserting the functions block.
$updatedContent = $parts[0] + $marker + "`n" + $functionsCodeblock + "`n" + $parts[1]

# Write the updated content to the target release script.
Write-Output "Building the release script at $targetScript"
Set-Content -Path $targetScript -Value $updatedContent -Encoding UTF8

#endregion

#region Build XML Descriptor

Write-Output "Updating XML Descriptor with module version information."

# Import the module manifest data to retrieve the version.
if (-not (Test-Path -Path $moduleManifest)) {
    Write-Error "Module manifest not found at $moduleManifest"
    exit
}

$manifest = Import-PowerShellDataFile -Path $moduleManifest

# Load the sb XML descriptor.
if (-not (Test-Path -Path $sbBasexml)) {
    Write-Error "Base XML file not found at $sbBasexml"
    exit
}
[xml]$sbXML = Get-Content -Path $sbBasexml -Raw

# Set the Version element to the module version.
$sbXML.ArrayOfSBADescriptor.SBADescriptor.Version = $manifest.ModuleVersion

#endregion

#region Compress & Encode Script

Write-Output "Compressing and encoding the release script."

# Read the target script as bytes and compress
$scriptText = Get-Content -Path $targetScript -Raw
$scriptBytes = [System.Text.Encoding]::Unicode.GetBytes($scriptText)

$compressedStream = New-Object System.IO.MemoryStream
$gZipStream = New-Object System.IO.Compression.GZipStream($compressedStream, [System.IO.Compression.CompressionMode]::Compress)
$gZipStream.Write($scriptBytes, 0, $scriptBytes.Length)
$gZipStream.Close()

# Retrieve the compressed bytes and encode to Base64.
$compressedBytes = $compressedStream.ToArray()
$encodedScriptData = [System.Convert]::ToBase64String($compressedBytes)

# Update the XML with the encoded script data.
$sbXML.ArrayOfSBADescriptor.SBADescriptor.ExecutionDescriptor.ScriptData = $encodedScriptData

#endregion

#region Finalize XML and Module Compression

# Update the DateModified element with the current timestamp.
$sbXML.ArrayOfSBADescriptor.SBADescriptor.DateModified = (Get-Date).ToString("o")

# Save the updated XML descriptor to the target location.
Write-Output "Saving updated XML descriptor to $sbTargetXML"
$sbXML.Save($sbTargetXML)

# Compress the module folder into a zip file.
Write-Output "Compressing the module folder into $moduleZip"
Compress-Archive -Path $moduleFolder -DestinationPath $moduleZip -Force

#endregion

Write-Output "Release packaging complete."