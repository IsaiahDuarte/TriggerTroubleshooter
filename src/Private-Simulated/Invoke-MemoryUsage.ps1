function Invoke-MemoryUsage {
    <#
        .SYNOPSIS
            Simulates memory usage using Testlimit.exe.
        .DESCRIPTION
            Downloads the Sysinternals Testlimit.exe, executes it for a given duration, and cleans up the temporary file.
        .PARAMETER Duration
            The duration in seconds to run the simulation.
        .EXAMPLE
            Invoke-MemoryUsage -Duration 60
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$Duration
    )

    Write-Verbose "Simulating memory usage: Target = $TargetPercentage% for Duration = $Duration seconds."

    $tempDir = [System.IO.Path]::GetTempPath()
    $tempExe = Join-Path -Path $tempDir -ChildPath "Testlimit.exe"
    $downloadUrl = "https://live.sysinternals.com/Testlimit64.exe"
    $arguments = "-d /accepteula"

    Write-Verbose "Downloading Testlimit.exe to '$tempExe' from Sysinternals."

    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempExe -UseBasicParsing
        Write-Verbose "Download completed successfully."

        Write-Verbose "Starting Testlimit.exe with arguments: $arguments."
        $proc = Start-Process -FilePath $tempExe -ArgumentList $arguments -NoNewWindow -PassThru

        Write-Verbose "Process started. Sleeping for duration plus buffer ($($Duration + 5) seconds)."
        Start-Sleep -Seconds ($Duration + 5)

        Write-Verbose "Stopping Testlimit.exe process."
        $proc | Stop-Process -Force
    }
    catch {
        Write-Error "Error in Invoke-MemoryUsage: $($_.Exception.Message)"
        return
    }
    finally {
        if (Test-Path $tempExe) {
            Remove-Item $tempExe -Force
            Write-Verbose "Cleaned up temporary Testlimit.exe."
        }
    }

    Write-Output "Memory usage simulation complete."
}
