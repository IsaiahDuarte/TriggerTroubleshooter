function Trace-TriggerData {
    <#
    .SYNOPSIS
        Captures data from a named trigger over a specified duration, writing the data to CSV.

    .DESCRIPTION
        Fetch store trigger data in a CSV file. Rotates files when size
        thresholds are reached and cleans up old files beyond the specified limit.

    .PARAMETER Name
        Name of the trigger to capture.
    
    .PARAMETER Records
        Specifies how many records from the dump will be collected and recorded

    .PARAMETER Duration
        How long to capture the data. Default is 1 minute.
    
    .PARAMETER CollectionInterval
        Specifies in seconds how long the delay is between data collection

    .PARAMETER CsvPath
        Where to store the CSV output. Defaults to a generated file in $ENV:TEMP.

    .PARAMETER FileSizeThreshold
        Maximum size (in bytes) of each CSV file before rolling over. Default is 5MB.
        This can be specified using PowerShell's byte literals, e.g., 2KB, 1MB, etc.

    .PARAMETER MaxFiles
        Number of rotated files to keep before deleting the oldest.

    .EXAMPLE
        Trace-TriggerData -Name "MyTrigger" -Duration 00:00:30
        Captures data for 30 seconds into a CSV file, rotating files at 2KB each, keeping 5 total.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $false)]
        [int] $Records = 100,

        [Parameter(Mandatory = $false)]
        [timespan] $Duration = (New-TimeSpan -Minutes 1),

        [Parameter(Mandatory = $false)]
        [int] $CollectionInterval = 2,

        [Parameter(Mandatory = $false)]
        [string] $CsvPath = (Join-Path -Path $ENV:TEMP -ChildPath "TraceTrigger_$([guid]::NewGuid()).csv"),

        [Parameter(Mandatory = $false)]
        [long] $FileSizeThreshold = 5MB,

        [Parameter(Mandatory = $false)]
        [int] $MaxFiles = 5
    )

    try {
        Write-Verbose "Getting Trigger"
        $trigger = Get-Trigger -Name $Name
        if (-not $trigger) {
            Write-Warning "Trigger with name '$Name' not found."
            return
        }
        Write-Verbose "Trigger found: $($trigger.TriggerName)"

        Write-Verbose "Getting trigger configuration"
        $triggerDetails = Get-CUTriggerDetails -TriggerId $trigger.TriggerId

        Write-Verbose "Getting Trigger Observable Details"
        $triggerObservableDetails = Get-CUObservableTriggerDetails -Trigger $Name

        Write-Verbose "Getting the Table"
        $table = Get-TableName -TableName $triggerObservableDetails.Table -TriggerType $triggerDetails.TriggerType

        Write-Verbose "Getting all columns"
        $columns = Get-TriggerColumns -FilterNodes $triggerDetails.FilterNodes

        # Track the start time
        $start_time = Get-Date

        Write-Verbose "Opening CSVWriter"
        $csvWriter = [CSVWriter]::new($CsvPath, $true)

        # A collection of all discovered headers
        $allHeaders = New-Object System.Collections.Generic.List[Object]

        # Keep track of CSV files for rotation
        $fileList = New-Object System.Collections.Generic.List[string]
        $currentFile = $CsvPath
        $fileCounter = 0

        do {
            try {
                Write-Verbose "Getting trigger dump"
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

                # Build headers only once (the first time we get data),
                # but we'll re-use them for any new rotated file if needed.
                if ($dumpData -and $allHeaders.Count -eq 0) {
                    foreach ($key in $dumpData.Keys) {
                        [void] $allHeaders.AddRange($dumpData[$key].PSObject.Properties.Name)
                    }
                    # Add a "TimeWritten" column for timestamp
                    [void] $allHeaders.Add("TimeWritten")

                    # Ensure uniqueness and sort if desired
                    $allHeaders = $allHeaders | Sort-Object -Unique

                    # Write headers to the initial file
                    $csvWriter.WriteHeaders($allHeaders)
                }

                # Check if we need to rotate the file
                if ($csvWriter.GetFileSize() -ge $FileSizeThreshold) {
                    Write-Verbose "Rotating file due to size threshold."
                    $csvWriter.Close()

                    $fileCounter++
                    $newFile = "{0}_{1}.csv" -f ($CsvPath.Replace(".csv", ""), $fileCounter)
                    [void] $fileList.Add($newFile)

                    # If we exceed the max file count, remove the oldest
                    if ($fileList.Count -gt $MaxFiles) {
                        $fileToRemove = $fileList[0]
                        if (Test-Path $fileToRemove) {
                            Remove-Item -Path $fileToRemove -Force -ErrorAction SilentlyContinue
                        }
                        $fileList.RemoveAt(0)
                    }

                    # Open the next file
                    $currentFile = $newFile
                    $csvWriter = [CSVWriter]::new($currentFile, $true)

                    # Optionally re-write the headers in the new file
                    if ($allHeaders.Count -gt 0) {
                        $csvWriter.WriteHeaders($allHeaders)
                    }
                }

                # Write data to file
                if ($dumpData) {
                    foreach ($key in $dumpData.Keys) {
                        $dump = $dumpData[$key]
                        $lineArray = foreach ($header in $allHeaders) {
                            if ($dump.PSObject.Properties[$header]) {
                                Format-CsvField -Value $dump.$header
                            }
                            elseif ($header -eq 'TimeWritten') {
                                (Get-Date).ToString("o")
                            }
                            else {
                                ""
                            }
                        }
                        $line = $lineArray -join ","
                        $csvWriter.WriteLine($line)
                    }

                    # Flush after each batch
                    $csvWriter.Stream.Flush()
                }

                Write-Verbose "Sleeping for $CollectionInterval seconds"
                Start-Sleep -Seconds $CollectionInterval
            }
            catch {
                Write-Error "An error occurred: $_"
                continue
            }

            $current_time = Get-Date
        } while ($current_time -lt ($start_time + $Duration))

        Write-Verbose "Data collection time range over"
    }
    catch {
        Write-Error -Message "Error in Trace-TriggerData: $($_.Exception.Message)" -ErrorAction Stop
    }
    finally {
        # Cleanup stream writer
        if ($csvWriter) {
            Write-Verbose "Closing file writer"
            $csvWriter.Close()
        }
    }
}

function Format-CsvField {
    <#
    .SYNOPSIS
        Helper function to escape CSV lines for Trace-TriggerData.
        
    .DESCRIPTION
        Checks if the incoming value contains any CSV special characters
        and if so, quotes and escapes the field as needed.

    .PARAMETER Value
        The text value that will be written into the CSV field.

    .EXAMPLE
        Format-CsvField -Value 'John Doe'
        John Doe
    #>
    param([string]$Value)

    # Characters that typically require quoting in a CSV field
    $charsToEscape = [char[]]('"', ',', "`n", "`r")

    # Check for any charsToEscape and escape if found
    if (![string]::IsNullOrEmpty($Value) -and ($Value.IndexOfAny($charsToEscape) -ge 0)) {
        $escaped = $Value.Replace('"', '""')
        return '"{0}"' -f $escaped
    }
    else {
        return $Value
    }
}

# Helper class to stream CSV writing
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
        $headerLine = $headers -join ","
        $this.Stream.WriteLine($headerLine)
        $this.Stream.Flush()
    }

    [long] GetFileSize() {
        return $this.Straem.BaseStream.Length
    }

    [void] Close() {
        $this.Stream.Flush()
        $this.Stream.Close()
    }
}