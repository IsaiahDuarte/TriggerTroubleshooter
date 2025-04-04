function Invoke-HighIO {
    <#
        .SYNOPSIS
            Simulate high disk I/O by continuously writing and reading files.
        .PARAMETER DurationSeconds
        .PARAMETER FileSizeMB
        .PARAMETER ThreadCount
        .PARAMETER TempPath
        .EXAMPLE
            PS> Invoke-HighIO -DurationSeconds 60 -FileSizeMB 100 -ThreadCount 4 -TempPath "C:\Temp"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$DurationSeconds,
        [Parameter(Mandatory = $false)]
        [int]$FileSizeMB = 100,
        [Parameter(Mandatory = $false)]
        [int]$ThreadCount = ([Environment]::ProcessorCount * 2),
        [Parameter(Mandatory = $false)]
        [string]$TempPath = $ENV:TEMP
    )

    if (-not (Test-Path -Path $TempPath)) {
        Write-Verbose "Creating directory $TempPath"
        New-Item -ItemType Directory -Path $TempPath -Force | Out-Null
    }

    $jobInfo = 1..$ThreadCount | ForEach-Object {
        @{
            FilePath = Join-Path $TempPath ("HighIO_Test_{0}.tmp" -f ([Guid]::NewGuid().ToString()))
        }
    }

    $scriptBlock = {
        param(
            $FilePath,
            $FileSizeMB,
            $DurationSeconds
        )

        Write-Verbose "[$(Get-Date)] Creating random data file: $FilePath ($FileSizeMB MB)"

        # Create initial random file
        $byteCount = $FileSizeMB * 1MB
        $data = New-Object byte[] $byteCount
        (New-Object System.Random).NextBytes($data)
        [System.IO.File]::WriteAllBytes($FilePath, $data)

        $fs = New-Object System.IO.FileStream(
            $FilePath,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::ReadWrite,
            [System.IO.FileShare]::None,
            4096,
            [System.IO.FileOptions]::WriteThrough
        )

        $stopTime = (Get-Date).AddSeconds($DurationSeconds)
        Write-Verbose "[$(Get-Date)] Starting I/O loop until $stopTime..."

        $bufferSize = 8192
        $rand = New-Object System.Random
        $readBuffer = New-Object byte[] $bufferSize
        $writeBuffer = New-Object byte[] $bufferSize

        while ((Get-Date) -lt $stopTime) {
            # Read
            $maxOffset = $fs.Length - $bufferSize
            if ($maxOffset -gt 0) {
                $readOffset = $rand.Next(0, [int]$maxOffset)
                $fs.Seek($readOffset, [System.IO.SeekOrigin]::Begin) | Out-Null
                $fs.Read($readBuffer, 0, $bufferSize) | Out-Null
            }

            # Write
            $rand.NextBytes($writeBuffer)
            if ($maxOffset -gt 0) {
                $writeOffset = $rand.Next(0, [int]$maxOffset)
                $fs.Seek($writeOffset, [System.IO.SeekOrigin]::Begin) | Out-Null
                $fs.Write($writeBuffer, 0, $bufferSize)
                $fs.Flush()
            }
        }

        $fs.Close()
        $fs.Dispose()

        Write-Verbose "[$(Get-Date)] I/O loop complete. Removing file: $FilePath"
        Remove-Item -Path $FilePath -ErrorAction SilentlyContinue -Force
    }

    Write-Verbose "Starting $ThreadCount job(s) for high I/O simulation..."
    $jobs = foreach ($info in $jobInfo) {
        Start-Job -ScriptBlock $scriptBlock -ArgumentList $info.FilePath, $FileSizeMB, $DurationSeconds
    }

    Wait-Job -Job $jobs | Out-Null
    Remove-Job -Job $jobs -Force | Out-Null

    Write-Host "High I/O simulation complete. All temporary files have been removed."
}
