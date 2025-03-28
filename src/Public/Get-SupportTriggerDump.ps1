function Get-SupportTriggerDump {
    <#
    .SYNOPSIS
        Exports trigger details into a ZIP file.

    .DESCRIPTION
        Retrieves specified trigger details and compresses them into a ZIP file in the provided directory.

    .PARAMETER Name
        Trigger name. Mandatory.

    .PARAMETER OutputDirectory
        Existing directory path, uses $ENV:TEMP by default if not specified.

    .EXAMPLE
        Get-SupportTriggerDump -Name "MyTrigger" -OutputDirectory "C:\Dumps"
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Name of the trigger to dump.")]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Mandatory = $false, HelpMessage = "Directory where the dump will be saved.")]
        [ValidateScript({ Test-Path $_ -PathType 'Container' })]
        [string] $OutputDirectory = $env:TEMP
    )

    Write-TTLog "Starting Get-SupportTriggerDump for TriggerName: '$Name'"
    Write-TTLog "OutputDirectory set to: '$OutputDirectory'"

    try {
        Write-TTLog "Retrieving trigger details..."
        $trigger = Get-Trigger -Name $Name

        # Check if the retrieved trigger exists
        if (-not $trigger) {
            Write-Warning "Unable to find trigger with name '$Name'. Exiting function."
            return
        }

        Write-TTLog "Trigger found. Id: $($trigger.Id)"

        # Create a unique temporary directory for storing dump files
        Write-TTLog "Creating temporary directory for dump files..."
        $tempRoot = [System.IO.Path]::GetTempPath()
        $tempDirectory = Join-Path -Path $tempRoot -ChildPath ([Guid]::NewGuid())
        New-Item -ItemType Directory -Path $tempDirectory | Out-Null
        Write-TTLog "Created temporary directory: $tempDirectory"

        # Export Trigger Details into JSON format
        $triggerDetails = Get-CUTriggerDetails -TriggerId $trigger.Id
        $triggerDetailsPath = Join-Path -Path $tempDirectory -ChildPath "TriggerDetails.json"
        Write-TTLog "Exporting Trigger Details to '$triggerDetailsPath'"
        $triggerDetails | ConvertTo-Json -Depth 20 -Compress | Out-File -FilePath $triggerDetailsPath -Encoding UTF8
        Write-TTLog "Trigger Details exported successfully."

        # Export Observable Trigger Details into JSON format
        $observableDetails = Get-CUObservableTriggerDetails -Trigger $Name
        $observableDetailsPath = Join-Path -Path $tempDirectory -ChildPath "ObservableTriggerDetails.json"
        Write-TTLog "Exporting Observable Trigger Details to '$observableDetailsPath'"
        $observableDetails | ConvertTo-Json -Depth 20 -Compress | Out-File -FilePath $observableDetailsPath -Encoding UTF8
        Write-TTLog "Observable Trigger Details exported successfully."

        # Prepare the ZIP file for the output
        $zipFileName = "$Name.zip"
        $zipFilePath = Join-Path -Path $OutputDirectory -ChildPath $zipFileName
        Write-TTLog "Compressing dump files into archive '$zipFilePath'"
        Compress-Archive -Path $tempDirectory -DestinationPath $zipFilePath -Force
        Write-TTLog "Compression completed successfully."

        # Clean up the temporary directory
        Write-TTLog "Removing temporary directory '$tempDirectory'"
        Remove-Item -Path $tempDirectory -Recurse -Force
        Write-TTLog "Temporary directory removed successfully."

        Write-Output "Trigger dump saved to '$zipFilePath'"
    }
    catch {
        Write-TTLog "ERROR: $($_.Exception.Message)"
        Write-Error "An error occurred during the trigger dump process: $($_.Exception.Message)"
        throw
    }
} 