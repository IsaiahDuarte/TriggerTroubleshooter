function Get-SupportTriggerDump {
    <#
    .SYNOPSIS
        Creates a dump of trigger details and compresses the results into a ZIP file. 

    .DESCRIPTION
        This function retrieves a trigger by name and exports its details, observable trigger details,
        and scoped dump to JSON files in a temporary directory. After exporting the files, it compresses
        the directory into a ZIP file saved in the specified output directory.

    .PARAMETER Name
        The name of the trigger to dump. This parameter is mandatory and cannot be null or empty.

    .PARAMETER OutputDirectory
        The directory where the ZIP file will be saved. This must be an existing directory.
        Defaults to the value of the TEMP environment variable.

    .EXAMPLE
        Get-SupportTriggerDump -Name "MyTrigger" -OutputDirectory "C:\Dumps"
        Retrieves all dump details for the trigger "MyTrigger" and saves the resulting ZIP file in "C:\Dumps".
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

        if (-not $trigger) {
            Write-Warning "Unable to find trigger with name '$Name'. Exiting function."
            return
        }

        Write-Verbose "Trigger found. TriggerID: $($trigger.TriggerID)"

        Write-Verbose "Creating temporary directory for dump files..."
        $tempRoot = [System.IO.Path]::GetTempPath()
        $tempDirectory = Join-Path -Path $tempRoot -ChildPath ([Guid]::NewGuid())

        New-Item -ItemType Directory -Path $tempDirectory | Out-Null
        Write-Verbose "Created temporary directory: $tempDirectory"

        # Export Trigger Details
        $triggerDetails = Get-CUTriggerDetails -TriggerId $trigger.TriggerID
        $triggerDetailsPath = Join-Path -Path $tempDirectory -ChildPath "TriggerDetails.json"
        Write-Verbose "Exporting Trigger Details to '$triggerDetailsPath'"
        $triggerDetails | ConvertTo-Json -Depth 20 -Compress | Out-File -FilePath $triggerDetailsPath -Encoding UTF8
        Write-Verbose "Trigger Details exported successfully."

        # Export Observable Trigger Details
        $observableDetails = Get-CUObservableTriggerDetails -Trigger $Name
        $observableDetailsPath = Join-Path -Path $tempDirectory -ChildPath "ObservableTriggerDetails.json"
        Write-Verbose "Exporting Observable Trigger Details to '$observableDetailsPath'"
        $observableDetails | ConvertTo-Json -Depth 20 -Compress | Out-File -FilePath $observableDetailsPath -Encoding UTF8
        Write-Verbose "Observable Trigger Details exported successfully."

        Write-Verbose "Determining table to query..."
        $table = Get-TableName -Name $observableDetails.Table -TriggerType $triggerDetails.TriggerType

        # Export Scoped Data
        $scopedDumpParams = @{
            Table                    = $table
            Name                     = $Name
            UseExport                = $true
            TriggerObservableDetails = $observableDetails
            TriggerType              = $triggerDetails.TriggerType
            Fields                   = $triggerDetails.FilterNodes.ExpressionDescriptor.Column
        }

        $scopedDumpPath = Join-Path -Path $tempDirectory -ChildPath "ScopedTriggerDump.json"
        Write-Verbose "Exporting Scoped Trigger Dump to '$scopedDumpPath'"
        Get-ScopedTriggerDump @scopedDumpParams | ConvertTo-Json -Compress -Depth 20 | Out-File -FilePath $scopedDumpPath -Encoding UTF8
        Write-Verbose "Scoped Trigger Dump exported successfully."

        # Prepare ZIP
        $zipFileName = "$Name.zip"
        $zipFilePath = Join-Path -Path $OutputDirectory -ChildPath $zipFileName
        Write-Verbose "Compressing dump files into archive '$zipFilePath'"
        Compress-Archive -Path $tempDirectory -DestinationPath $zipFilePath -Force
        Write-Verbose "Compression completed successfully."

        Write-Verbose "Removing temporary directory '$tempDirectory'"
        Remove-Item -Path $tempDirectory -Recurse -Force
        Write-Verbose "Temporary directory removed successfully."

        Write-Output "Trigger dump saved to '$zipFilePath'"
    }
    catch {
        Write-Error "An error occurred during the trigger dump process: $($_.Exception.Message)"
    }
} 