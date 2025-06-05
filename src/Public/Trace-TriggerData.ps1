function Trace-TriggerData {
    <#
    .SYNOPSIS
        Capture data from a trigger into CSV (optionally as a background job)
    
    .DESCRIPTION
        Dump data, rotate files by size, and optionally run as a background job
    
    .PARAMETER Name
        Trigger name case sensitive
    
    .PARAMETER Records
        Number of records to be returned in the Invoke-CUQuery function
    
    .PARAMETER Duration
        How long to capture
    
    .PARAMETER CollectionInterval
        Seconds between collections
    
    .PARAMETER CsvPath
        Where CSV is stored
    
    .PARAMETER FileSizeThreshold
        When to rotate files
    
    .PARAMETER MaxFiles
      Number of rotated files to keep

    .PARAMETER OnTrigger
        When provided, it will only dump the last 15 minutes of records to the disk
        when the trigger fires
    
    .PARAMETER TriggerDataRententionInMinutes
        The number in minutes where trigger data is stored in memory when
        OnTrigger is specified
    
    .EXAMPLE
        Trace-TriggerData -Name "MyTrigger" -AsJob
    #>
    [CmdletBinding(DefaultParameterSetName = 'Trace')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Trace')]
        [Parameter(Mandatory = $true, ParameterSetName = 'DumpOnFire')]
        [string] $Name,
            
        [Parameter(Mandatory = $false, ParameterSetName = 'Trace')]
        [Parameter(Mandatory = $false, ParameterSetName = 'DumpOnFire')]
        [int] $Records = 100,
    
        [Parameter(Mandatory = $false, ParameterSetName = 'Trace')]
        [Parameter(Mandatory = $false, ParameterSetName = 'DumpOnFire')]
        [timespan] $Duration = (New-TimeSpan -Minutes 1),
    
        [Parameter(Mandatory = $false, ParameterSetName = 'Trace')]
        [Parameter(Mandatory = $false, ParameterSetName = 'DumpOnFire')]
        [int] $CollectionInterval = 2,
    
        [Parameter(Mandatory = $false, ParameterSetName = 'Trace')]
        [Parameter(Mandatory = $false, ParameterSetName = 'DumpOnFire')]
        [string] $CsvPath = (Join-Path $env:TEMP "TraceTrigger_$([guid]::NewGuid()).csv"),
    
        [Parameter(Mandatory = $false, ParameterSetName = 'Trace')]
        [Parameter(Mandatory = $false, ParameterSetName = 'DumpOnFire')]
        [long] $FileSizeThreshold = 5MB,

        [Parameter(Mandatory = $false, ParameterSetName = 'Trace')]
        [Parameter(Mandatory = $false, ParameterSetName = 'DumpOnFire')]
        [int] $MaxFiles = 5,
        
        [Parameter(Mandatory = $false, ParameterSetName = 'DumpOnFire')]
        [int] $TriggerDataRententionInMinutes = 15,

        [Parameter(Mandatory = $false, ParameterSetName = 'DumpOnFire')]
        [switch] $OnTrigger
    )

    Write-Output "Saving results to: $CsvPath"
    Write-TTLog "Saving results to: $CsvPath"
    
    try {
        Write-TTLog "Getting Trigger"
        $trigger = Get-Trigger -Name $Name
        if (-not $trigger) {
            Write-Warning "Trigger '$Name' not found"
            return
        }

        Write-TTLog "Getting trigger configuration"
        $triggerDetails = Get-CUTriggerDetails -TriggerId $trigger.Id

        Write-TTLog "Getting Trigger Observable Details"
        $triggerObservableDetails = Get-CUObservableTriggerDetails -Trigger $Name

        # Sometimes when a trigger is disabled, then gets enabled, Get-CUObservableTriggerDetails returns empty filter/table
        if ($triggerObservableDetails.Filters.Count -eq 0) {
            $triggerObservableDetails.Filters = Get-TriggerColumns -FilterNodes $triggerDetails.FilterNodes
        }

        if ([string]::IsNullOrEmpty($triggerObservableDetails.Table)) {
            $triggerObservableDetails.Table = $triggerDetails.TableName
        }
            
        Write-TTLog "Getting the Table"
        $table = Get-TableName -TableName $triggerObservableDetails.Table -TriggerType $triggerDetails.TriggerType

        Write-TTLog "Getting columns"
        $columns = Get-TriggerColumns -FilterNodes $triggerDetails.FilterNodes
            
        $startTime = Get-Date

        Write-TTLog "Opening CSVWriter"
        $csvWriter = [CSVWriter]::new($CsvPath, $true)
        $allHeaders = [System.Collections.Generic.List[Object]]::new()
        $fileList = [System.Collections.Generic.List[string]]::new()
        $csvData = [System.Collections.Generic.List[PSCustomObject]]::new()
        $currentFile = $CsvPath
        $fileCounter = 0

        Write-TTLog "Getting Trigger Configuration to see when the trigger last fired"
        $configuration = Get-TriggerConfiguration -Name $Name
        [DateTime] $lastTriggerFire = $configuration.LastIncidentCreation
    
        do {
            try {
                Write-TTLog "Getting dump"
                $dumpSplat = @{
                    Name                     = $Name
                    Fields                   = $columns
                    Table                    = $table
                    TriggerObservableDetails = $triggerObservableDetails
                    TriggerType              = $triggerDetails.TriggerType
                    Take                     = $Records
                    SkipTableValidation      = $true
                }
                $dumpData = Get-ScopedTriggerDump @dumpSplat

                # Build headers only once the first time we get data
                if ($dumpData -and $allHeaders.Count -eq 0) {
                    foreach ($key in $dumpData.Keys) {
                        $allHeaders.AddRange($dumpData[$key].PSObject.Properties.Name)
                    }
                    $allHeaders.Add("TimeWritten")
                    $allHeaders = $allHeaders | Sort-Object -Unique
                    $csvWriter.WriteHeaders($allHeaders)
                }

                # Check if we need to rotate the file
                if ($csvWriter.GetFileSize() -ge $FileSizeThreshold) {
                    Write-TTLog "Rotating file"
                    $csvWriter.Close()
                    $fileCounter++
                    $newFile = "{0}_{1}.csv" -f ($CsvPath -replace '\.csv$', ''), $fileCounter
                    $fileList.Add($newFile)
                    if ($fileList.Count -gt $MaxFiles) {
                        $fileToRemove = $fileList[0]
                        if (Test-Path $fileToRemove) {
                            Remove-Item -Path $fileToRemove -Force -ErrorAction SilentlyContinue
                        }
                        $fileList.RemoveAt(0)
                    }
                    $currentFile = $newFile
                    $csvWriter = [CSVWriter]::new($currentFile, $true)
                    if ($allHeaders.Count -gt 0) {
                        $csvWriter.WriteHeaders($allHeaders)
                    }
                }
                
                # Dump the data to array or file if available
                if ($dumpData) {
                    $timeWritten = (Get-Date)
                    $timeWrittenAsString = $timeWritten.ToString("o")
                    foreach ($key in $dumpData.Keys) {
                        $dump = $dumpData[$key]
                        $lineArray = foreach ($header in $allHeaders) {
                            if ($dump.PSObject.Properties[$header]) {
                                Format-CsvField -Value $dump.$header
                            }
                            elseif ($header -eq 'TimeWritten') {
                                $timeWrittenAsString
                            }
                            else {
                                ""
                            }
                        }
                        $line = $lineArray -join ","

                        if ($OnTrigger) {
                            $obj = [pscustomobject]@{
                                CSVLine     = $line
                                TimeWritten = $timeWritten
                            }
                            [void] $csvData.Add($obj)
                        }
                        else {
                            $csvWriter.WriteLine($line)
                        }
                    }

                    $csvWriter.Stream.Flush()
                }
                # Drop extra data
                if ($OnTrigger) {
                    Write-TTLog "Rows in memory: $($csvData.Count)"
                    $csvData = $csvData.Where({
                            $_.TimeWritten -ge ((Get-Date).AddMinutes(-1 * $TriggerDataRententionInMinutes))
                        })
                    Write-TTLog "Rows in memory after retention cleaning: $($csvData.Count)"
                }

                # See if the trigger has fired
                if ($OnTrigger) {
                    Write-TTLog "Getting trigger configuration"
                    $configuration = Get-TriggerConfiguration -Name $Name
                    
                    Write-TTLog "LastIncidentCreation: $($configuration.LastIncidentCreation)"
                    if ([DateTime] $configuration.LastIncidentCreation -gt $lastTriggerFire) {
                        Write-TTLog "LastIncidentCreation is greater than $lastTriggerFire... writing data"
                        $csvData.foreach({
                                $csvWriter.WriteLine($_.CSVLine)
                            })
                        $lastTriggerFire = $configuration.LastIncidentCreation
                    }
                    else {
                        Write-TTLog "Last inspection time is not less than $lastTriggerFire"
                    }
                }
    
                Write-TTLog "Sleeping for $CollectionInterval seconds"
                Start-Sleep -Seconds $CollectionInterval
            }
            catch {
                Write-Error "Error: $_"
                continue
            }
            $currentTime = Get-Date
        } while ($currentTime -lt ($startTime + $Duration))
    
        Write-TTLog "Done"
    }
    catch {
        Write-Error "Error in Trace-TriggerData: $($_.Exception.Message)"
    }
    finally {
        if ($csvWriter) {
            Write-TTLog "Closing writer"
            $csvWriter.Close()
        }
    }
}
    
function Format-CsvField {
    <#
    .SYNOPSIS
      Escape CSV fields
    #>
    param([string]$Value)
    $charsToEscape = [char[]]('"', ',', "`n", "`r")
    if (![string]::IsNullOrEmpty($Value) -and ($Value.IndexOfAny($charsToEscape) -ge 0)) {
        $escaped = $Value.Replace('"', '""')
        return '"{0}"' -f $escaped
    }
    else {
        return $Value
    }
}
    
class CSVWriter {
    [string] $FilePath
    [System.IO.StreamWriter] $Stream
    
    CSVWriter([string] $filePath, [bool] $append = $true) {
        $this.FilePath = $filePath
        $this.Stream = [System.IO.StreamWriter]::new($filePath, $append)
    }
    
    [void] WriteLine([string] $line) {
        $this.Stream.WriteLine($line)
    }
    
    [void] WriteHeaders([string[]] $headers) {
        $this.Stream.WriteLine($headers -join ",")
        $this.Stream.Flush()
    }
    
    [long] GetFileSize() {
        return $this.Stream.BaseStream.Length
    }
    
    [void] Close() {
        $this.Stream.Flush()
        $this.Stream.Close()
    }
}