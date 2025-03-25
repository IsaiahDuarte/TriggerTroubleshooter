function Invoke-DiskUsage {
    <#
        .SYNOPSIS
            Simulates disk usage by creating a large file that occupies free space
            so that only the specified percentage remains free on a given drive.
            
        .PARAMETER RemainingPercentage
        .PARAMETER Duration
        .PARAMETER Drive
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 99)]
        [int]$RemainingPercentage,
        
        [Parameter(Mandatory = $true)]
        [int]$Duration,
        
        [Parameter(Mandatory = $false)]
        [string]$Drive = $env:SystemDrive
    )
    
    if ($Drive -notmatch ':\\$') {
        $Drive = $Drive.TrimEnd(':') + ":\"
    }
    
    try {
        $driveInfo = New-Object System.IO.DriveInfo($Drive)
        if (-not $driveInfo.IsReady) {
            Write-Error "Drive $Drive is not ready."
            return
        }
        $totalSpace = $driveInfo.TotalSize
        $currentFree = $driveInfo.AvailableFreeSpace

        Write-Verbose "Drive: $Drive"
        Write-Verbose ("Total Space: {0:N0} bytes" -f $totalSpace)
        Write-Verbose ("Current Free: {0:N0} bytes" -f $currentFree)

        $targetFree = [Math]::Floor($totalSpace * ($RemainingPercentage / 100))
        $padding = [Math]::Floor($totalSpace * 0.02)
        $fillSize = $currentFree - $targetFree + $padding

        if ($fillSize -le 0) {
            Write-Warning "There is not enough free space on $Drive to simulate this disk usage scenario. " +
            "Current free space is already below or equal to the target free space plus padding."
            return
        }
        
        $tempFile = Join-Path -Path $Drive -ChildPath ("tempDiskFill_{0}.tmp" -f (Get-Date -Format "yyyyMMddHHmmss"))
        Write-Output "Creating temporary file '$tempFile' with size $fillSize bytes to simulate disk usage..."
        
        $fsutilCommand = "fsutil file createnew `"$tempFile`" $fillSize"
        Write-Verbose "Running: $fsutilCommand"
        Invoke-Expression $fsutilCommand
        
        Write-Output "Temporary file created. Waiting for $Duration seconds..."
        Start-Sleep -Seconds $Duration
        
        Write-Output "Duration elapsed. Deleting temporary file..."
        Remove-Item -Path $tempFile -Force
        Write-Output "Disk usage simulation complete. Free space should be restored (allowing for OS buffering delay)."
    }
    catch {
        Write-Error "Error in Invoke-DiskUsage: $($_.Exception.Message)"
    }
}