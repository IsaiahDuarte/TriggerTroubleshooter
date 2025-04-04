function Invoke-ExeSimulation {
    <#
        .SYNOPSIS
            Finds an executable by name, starts it,
            waits one second, then stops the process.

        .PARAMETER ExeName
            Name of the executable to run.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ExeName
    )


    try {
        $exePath = Find-ExePath -Name $ExeName

        if (-not $exePath) {
            Write-Error "Executable '$ExeName' not found using Get-Command, where.exe, or registry App Paths."
            return
        }

        Write-Verbose "Found $ExeName at $exePath sleeping for 15 seconds"

        Start-Sleep -Seconds 15


        # Start the process and capture the process
        $process = Start-Process -FilePath $exePath -PassThru
        Write-Output "Started process '$ExeName' (PID: $($process.Id)). Waiting for 15 second..."

        Start-Sleep -Seconds 15

        # Stop the process
        Write-Output "15 second elapsed; stopping process."
        Stop-Process -Id $process.Id -Force
        Write-Output "Process '$ExeName' (PID: $($process.Id)) stopped."
    }
    catch {
        Write-Error "Error: $($_.Exception.Message)"
    }
}