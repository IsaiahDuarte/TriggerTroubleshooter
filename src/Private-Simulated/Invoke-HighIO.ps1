function Invoke-HighIO {
    <#
        .SYNOPSIS
            Simulate high disk I/O by continuously writing and reading files.

        .PARAMETER DurationSeconds
        .PARAMETER FileSizeMB
        .PARAMETER ThreadCount
        .PARAMETER TempPath

        .EXAMPLE
            PS> Invoke-HighIO -DurationSeconds 60 -FileSizeMB 100 -ThreadCount 2 -TempPath "C:\Temp"
            Runs a 60-second high I/O simulation with 2 worker threads, each creating/downloading a 100 MB file in C:\Temp.

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]
        $DurationSeconds,

        [Parameter(Mandatory = $true)]
        [int]
        $FileSizeMB,

        [Parameter(Mandatory = $true)]
        [int]
        $ThreadCount,

        [Parameter(Mandatory = $false)]
        [string]
        $TempPath = "$env:SystemDrive\Temp"
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
        [byte[]] $fileBytes = New-Object byte[] ($FileSizeMB * 1MB)
        (New-Object System.Random).NextBytes($fileBytes)
        [System.IO.File]::WriteAllBytes($FilePath, $fileBytes)

        $stopTime = (Get-Date).AddSeconds($DurationSeconds)
        Write-Verbose "[$(Get-Date)] Starting read/write loop until $stopTime..."

        while ((Get-Date) -lt $stopTime) {
            [void][System.IO.File]::ReadAllBytes($FilePath)

            $fs = [System.IO.File]::Open($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite)
            try {
                $randomOffset = (Get-Random -Minimum 0 -Maximum ($FileSizeMB * 1MB - 8192))
                $fs.Seek($randomOffset, [System.IO.SeekOrigin]::Begin) | Out-Null

                [byte[]] $overwriteData = New-Object byte[] 8192
                (New-Object System.Random).NextBytes($overwriteData)
                $fs.Write($overwriteData, 0, $overwriteData.Length)
            }
            finally {
                $fs.Close()
                $fs.Dispose()
            }
        }

        Write-Verbose "[$(Get-Date)] Done. Removing file: $FilePath"
        Remove-Item -Path $FilePath -ErrorAction SilentlyContinue -Force
    }

    Write-Verbose "Starting $ThreadCount job(s) for high I/O simulation..."
    $jobs = foreach ($info in $jobInfo) {
        Start-Job -ScriptBlock $scriptBlock -ArgumentList $info.FilePath, $FileSizeMB, $DurationSeconds
    }

    Wait-Job -Job $jobs | Out-Null
    Receive-Job -Job $jobs | Out-Null
    Remove-Job -Job $jobs -Force | Out-Null

    Write-Host "High I/O simulation complete. All temporary files have been removed."
}