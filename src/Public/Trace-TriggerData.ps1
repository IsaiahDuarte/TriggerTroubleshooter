function Trace-TriggerData {
    <#
    .SYNOPSIS
      Capture data from a trigger into CSV (optionally as a background job)
    
    .DESCRIPTION
      Dump data, rotate files by size, and optionally run as a background job
    
    .PARAMETER Name
      Trigger name
    
    .PARAMETER Records
      Number of records
    
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
    
    .PARAMETER AsJob
      Run this capture as a background job
    
    .EXAMPLE
      Trace-TriggerData -Name "MyTrigger" -AsJob
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
            [string] $CsvPath = (Join-Path $env:TEMP "TraceTrigger_$([guid]::NewGuid()).csv"),
    
            [Parameter(Mandatory = $false)]
            [long] $FileSizeThreshold = 5MB,
    
            [Parameter(Mandatory = $false)]
            [int] $MaxFiles = 5,
    
            [Parameter(Mandatory = $false)]
            [switch] $AsJob
        )
    
        if ($AsJob) {
            $CUPath = (Get-Module -Name ControlUp.Powershell.User).Path
            $ModulePath = (Get-Module -Name TriggerTroubleshooter).Path
            Start-Job -Name "TraceTriggerData-$Name" -ScriptBlock {
                Import-Module $using:ModulePath,$using:CUPath
                Trace-TriggerData -Name $using:Name -Records $using:Records -Duration $using:Duration -CollectionInterval $using:CollectionInterval -CsvPath $using:CsvPath -FileSizeThreshold $using:FileSizeThreshold -MaxFiles $using:MaxFiles
            }
            return
        }
    
        try {
            Write-TriggerTroubleshooterLog "Getting Trigger"
            $trigger = Get-Trigger -Name $Name
            if (-not $trigger) {
                Write-Warning "Trigger '$Name' not found"
                return
            }

            Write-TriggerTroubleshooterLog "Getting trigger configuration"
            $triggerDetails = Get-CUTriggerDetails -TriggerId $trigger.Id

            Write-TriggerTroubleshooterLog "Getting Trigger Observable Details"
            $triggerObservableDetails = Get-CUObservableTriggerDetails -Trigger $Name

            Write-TriggerTroubleshooterLog "Getting the Table"
            $table = Get-TableName -TableName $triggerObservableDetails.Table -TriggerType $triggerDetails.TriggerType

            Write-TriggerTroubleshooterLog "Getting columns"
            $columns = Get-TriggerColumns -FilterNodes $triggerDetails.FilterNodes
            
            $start_time = Get-Date

            Write-TriggerTroubleshooterLog "Opening CSVWriter"
            $csvWriter = [CSVWriter]::new($CsvPath, $true)
            $allHeaders = [System.Collections.Generic.List[Object]]::new()
            $fileList = [System.Collections.Generic.List[string]]::new()
            $currentFile = $CsvPath
            $fileCounter = 0
    
            do {
                try {
                    Write-TriggerTroubleshooterLog "Getting dump"
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
                        Write-TriggerTroubleshooterLog "Rotating file"
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
                        $csvWriter.Stream.Flush()
                    }
    
                    Write-TriggerTroubleshooterLog "Sleeping for $CollectionInterval seconds"
                    Start-Sleep -Seconds $CollectionInterval
                }
                catch {
                    Write-Error "Error: $_"
                    continue
                }
                $current_time = Get-Date
            } while ($current_time -lt ($start_time + $Duration))
    
            Write-TriggerTroubleshooterLog "Done"
        }
        catch {
            Write-Error "Error in Trace-TriggerData: $($_.Exception.Message)"
        }
        finally {
            if ($csvWriter) {
                Write-TriggerTroubleshooterLog "Closing writer"
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