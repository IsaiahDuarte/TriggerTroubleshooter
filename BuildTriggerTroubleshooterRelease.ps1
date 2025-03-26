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
    Updated:           2/24/2025
    Context:           This script was made to package TriggerTroubleshooter

#>
param(
    [bool]$RunIntegrationTests = $false
)

function Update-ReleaseScript {
    [CmdletBinding()]
    param(
        # An array of file paths containing the function scripts.
        [Parameter(Mandatory = $true)]
        [string[]]$Files,

        # The base script file that contains the marker.
        [Parameter(Mandatory = $true)]
        [string]$sbBase,

        # The marker string to search for in the base script.
        [Parameter(Mandatory = $true)]
        [string]$marker,

        # The path for the updated target release script.
        [Parameter(Mandatory = $true)]
        [string]$targetScript
    )

    # Create a list to hold the functions code block.
    $functionsCode = New-Object 'System.Collections.Generic.List[string]'

    foreach ($file in $Files) {
        if (-not (Test-Path -Path $file)) {
            Write-Warning "File not found: $file. Skipping."
            continue
        }

        $header = "`n`n#region $([System.IO.Path]::GetFileName($file))`n"
        $footer = "`n#endregion`n`n"
        $codeBlock = Get-Content -Path $file -Raw
        $functionsCode.Add($header)
        $functionsCode.Add($codeBlock)
        $functionsCode.Add($footer)
    }
    $functionsCodeblock = [string]::Join("", $functionsCode)

    # Read the base script content.
    if (-not (Test-Path -Path $sbBase)) {
        Write-Error "Base script not found at $sbBase"
        return
    }
    $sbBaseContent = Get-Content -Path $sbBase -Raw

    # Verify that the marker exists in the base script.
    if (-not $sbBaseContent.Contains($marker)) {
        Write-Error "The marker '$marker' was not found in $sbBase"
        return
    }

    # Split the base script content on the marker.
    $parts = $sbBaseContent -split [regex]::Escape($marker)
    if ($parts.Count -ne 2) {
        Write-Error "Unable to split $sbBase using the marker."
        return
    }

    # Build the updated script content by inserting the functions block.
    $updatedContent = $parts[0] + $marker + "`n" + $functionsCodeblock + "`n" + $parts[1]

    # Write the updated content to the target release script.
    Write-Output "Building the release script at $targetScript"
    Set-Content -Path $targetScript -Value $updatedContent -Encoding UTF8
}

#region Initialization

# Define paths relative to the current script location.
$releaseFolder = Join-Path -Path $PSScriptRoot -ChildPath "Release"

# Base script for release build.
$sbBase = Join-Path -Path $PSScriptRoot -ChildPath "sb_base.ps1"

# New simulated base script for the simulated XML.
$simulatedSBBase = Join-Path -Path $PSScriptRoot -ChildPath "simulated_sb_base.ps1"

$moduleFolder = Join-Path -Path $PSScriptRoot -ChildPath "src"
$publicFolder = Join-Path -Path $moduleFolder -ChildPath "Public"
$privateFolder = Join-Path -Path $moduleFolder -ChildPath "Private"
$privateSimulatedFolder = Join-Path -Path $moduleFolder -ChildPath "Private-Simulated"
$moduleZip = Join-Path -Path $PSScriptRoot -ChildPath "Release\TriggerTroubleshooter.zip"

$targetScript = Join-Path -Path $PSScriptRoot -ChildPath "Release\ScriptAction.ps1"
$targetSimulatedScript = Join-Path -Path $PSScriptRoot -ChildPath "Release\ScriptAction-Simulated.ps1"
# Base XML descriptor file (used as a template).
$sbBasexml = Join-Path -Path $PSScriptRoot -ChildPath "sb_base.xml"
$sbSimBasexml = Join-Path -Path $PSScriptRoot -ChildPath "simulated_sb_base.xml"

# Target XML for the normal build.
$sbTargetXML = Join-Path -Path $PSScriptRoot -ChildPath "Release\Trigger Troubleshooter.xml"

# Target XML for the simulated build.
$simulatedTargetXML = Join-Path -Path $PSScriptRoot -ChildPath "Release\Trigger Troubleshooter - Simulated Test.xml"

$moduleManifest = Join-Path -Path $PSScriptRoot -ChildPath "src\TriggerTroubleshooter.psd1"

$integrationTestPath = Join-Path -Path $PSScriptRoot -ChildPath "tests\integration\"
$unitTestPath = Join-Path -Path $PSScriptRoot -ChildPath "tests\unit\"
$marker = "###ImportModule###"

# Ensure the release folder exists.
if (-not (Test-Path -Path $releaseFolder)) {
    Write-TTLog "Release folder not found. Creating folder at $releaseFolder"
    New-Item -ItemType Directory -Path $releaseFolder | Out-Null
}

#endregion

#region Unit Tests
Write-Output "Starting unit tests in $unitTestPath"
Set-Location -Path $unitTestPath
$testResult = Invoke-Pester -PassThru
if ($testResult.TotalCount -eq $testResult.PassedCount) {
    Write-Output "Unit tests passed"
}
else {
    exit 1
}
#endregion

#region Integration Tests
if ($RunIntegrationTests) {
    Write-Output "Starting integration tests in $integrationTestPath"
    Set-Location -Path $integrationTestPath
    $testResult = "Invoke-Pester -Path '$integrationTestPath'" | powershell.exe -NoProfile -NonInteractive -NoLogo -ExecutionPolicy Bypass -Command -
    if ([Regex]::Match($testResult[-1], "Failed: 0").Success) {
        Write-Output "Integration tests passed"
    }
    else {
        exit 1
    }
}
#endregion

#region Build Script

Write-Output "Collecting module functions from $publicFolder $privateFolder"

# Get all .ps1 files from the module folder
$functions = Get-ChildItem -Path $publicFolder, $privateFolder -Filter *.ps1 -Recurse
$simulatedFunctions = Get-ChildItem -Path $privateSimulatedFolder -Filter *.ps1 -Recurse
Update-ReleaseScript -Files $functions.FullName -sbBase $sbBase -marker $marker -targetScript $targetScript
Update-ReleaseScript -Files $simulatedFunctions.FullName -sbBase $simulatedSBBase -marker $marker -targetScript $targetSimulatedScript
#endregion

#region Build XML Descriptor

Write-Output "Updating XML Descriptor with module version information."

# Import the module manifest data to retrieve the version.
if (-not (Test-Path -Path $moduleManifest)) {
    Write-Error "Module manifest not found at $moduleManifest"
    exit
}

$manifest = Import-PowerShellDataFile -Path $moduleManifest

# Load the base XML descriptor.
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

# Read the target script as bytes and compress.
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

#region Build Simulated XML Descriptor

Write-Output "Building simulated XML Descriptor using simulated base script at $simulatedSBBase"

# Read the simulated base script content.
if (-not (Test-Path -Path $simulatedSBBase)) {
    Write-Error "Simulated base script not found at $simulatedSBBase"
    exit
}

$simBaseContent = Get-Content -Path $targetSimulatedScript -Raw

# Compress and encode the simulated updated content.
$simScriptBytes = [System.Text.Encoding]::Unicode.GetBytes($simBaseContent)
$simCompressedStream = New-Object System.IO.MemoryStream
$simGZipStream = New-Object System.IO.Compression.GZipStream($simCompressedStream, [System.IO.Compression.CompressionMode]::Compress)
$simGZipStream.Write($simScriptBytes, 0, $simScriptBytes.Length)
$simGZipStream.Close()

$simCompressedBytes = $simCompressedStream.ToArray()
$simEncodedScriptData = [System.Convert]::ToBase64String($simCompressedBytes)

[xml]$simXML = Get-Content -Path $sbSimBasexml -Raw

# Set the version and update the ExecutionDescriptor with the simulated script data.
$simXML.ArrayOfSBADescriptor.SBADescriptor.Version = $manifest.ModuleVersion
$simXML.ArrayOfSBADescriptor.SBADescriptor.ExecutionDescriptor.ScriptData = $simEncodedScriptData
$simXML.ArrayOfSBADescriptor.SBADescriptor.DateModified = (Get-Date).ToString("o")

# Save the simulated XML descriptor.
Write-Output "Saving updated simulated XML descriptor to $simulatedTargetXML"
$simXML.Save($simulatedTargetXML)

#endregion

Write-Output "Release packaging complete."