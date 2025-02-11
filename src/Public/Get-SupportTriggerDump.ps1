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

    Write-Verbose "Starting Get-SupportTriggerDump for TriggerName: '$Name'"
    Write-Verbose "OutputDirectory set to: '$OutputDirectory'"

    try {
        Write-Verbose "Retrieving trigger details..."
        $trigger = Get-CUTriggers | Where-Object { $_.TriggerName -eq $Name }

        # Check if the retrieved trigger exists
        if (-not $trigger) {
            Write-Warning "Unable to find trigger with name '$Name'. Exiting function."
            return
        }

        Write-Verbose "Trigger found. TriggerID: $($trigger.TriggerID)"

        # Create a unique temporary directory for storing dump files
        Write-Verbose "Creating temporary directory for dump files..."
        $tempRoot = [System.IO.Path]::GetTempPath()
        $tempDirectory = Join-Path -Path $tempRoot -ChildPath ([Guid]::NewGuid())
        New-Item -ItemType Directory -Path $tempDirectory | Out-Null
        Write-Verbose "Created temporary directory: $tempDirectory"

        # Export Trigger Details into JSON format
        $triggerDetails = Get-CUTriggerDetails -TriggerId $trigger.TriggerID
        $triggerDetailsPath = Join-Path -Path $tempDirectory -ChildPath "TriggerDetails.json"
        Write-Verbose "Exporting Trigger Details to '$triggerDetailsPath'"
        $triggerDetails | ConvertTo-Json -Depth 20 -Compress | Out-File -FilePath $triggerDetailsPath -Encoding UTF8
        Write-Verbose "Trigger Details exported successfully."

        # Export Observable Trigger Details into JSON format
        $observableDetails = Get-CUObservableTriggerDetails -Trigger $Name
        $observableDetailsPath = Join-Path -Path $tempDirectory -ChildPath "ObservableTriggerDetails.json"
        Write-Verbose "Exporting Observable Trigger Details to '$observableDetailsPath'"
        $observableDetails | ConvertTo-Json -Depth 20 -Compress | Out-File -FilePath $observableDetailsPath -Encoding UTF8
        Write-Verbose "Observable Trigger Details exported successfully."

        # Prepare the ZIP file for the output
        $zipFileName = "$Name.zip"
        $zipFilePath = Join-Path -Path $OutputDirectory -ChildPath $zipFileName
        Write-Verbose "Compressing dump files into archive '$zipFilePath'"
        Compress-Archive -Path $tempDirectory -DestinationPath $zipFilePath -Force
        Write-Verbose "Compression completed successfully."

         # Clean up the temporary directory
        Write-Verbose "Removing temporary directory '$tempDirectory'"
        Remove-Item -Path $tempDirectory -Recurse -Force
        Write-Verbose "Temporary directory removed successfully."

        Write-Output "Trigger dump saved to '$zipFilePath'"
    }
    catch {
        Write-Error "An error occurred during the trigger dump process: $($_.Exception.Message)"
        throw
    }
} 