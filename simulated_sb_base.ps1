<#
    .SYNOPSIS
       Helper script for Trigger Troubleshooter Simulations

    .DESCRIPTION
        This script will simulate trigger conditions like creating a windows event.

    .NOTES 
        Version:           1.2.1
        Context:           Made for Trigger Troubleshooter
        Author:            Isaiah Duarte ->  https://github.com/IsaiahDuarte/TriggerTroubleshooter  
        Requires:          The CU Monitor's ControlUp.PowerShell.User.dll & 9.0.5+
        Creation Date:     2/23/2025    
        Links:
        Updated:           
#>

param (
    [Parameter(Mandatory = $true)]
    [string] $TestType,

    [Parameter(Mandatory = $false)]
    [string] $LogName,

    [Parameter(Mandatory = $false)]
    [string] $Source,

    [Parameter(Mandatory = $false)]
    [string] $EventID,

    [Parameter(Mandatory = $false)]
    [string] $EntryType,
    
    [Parameter(Mandatory = $false)]
    [string] $Message,
    
    [Parameter(Mandatory = $false)]
    [string] $Duration,

    [Parameter(Mandatory = $false)]
    [string] $DiskSpacePercentage
)

$code = @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;


public class CpuTester
{
    private volatile bool _running = false;
    private List<Thread> _threads = new List<Thread>();

    /// Start generating CPU load. 
    /// cpuUsage: an integer between 0 and 100 representing the percentage of CPU load per thread.
    /// durationMilliseconds: how long (in milliseconds) to generate load.
    public void Start(int cpuUsage, int durationMilliseconds)
    {
        if (cpuUsage < 0 || cpuUsage > 100)
            throw new ArgumentOutOfRangeException("cpuUsage", "Please specify a percentage between 0 and 100.");

        if (_running)
            throw new InvalidOperationException("CPU load is already running.");

        _running = true;

        // Launch one thread per processor.
        for (int i = 0; i < Environment.ProcessorCount; i++)
        {
            Thread t = new Thread(new ParameterizedThreadStart(GenerateLoad));
            t.IsBackground = true;
            t.Start(cpuUsage);
            _threads.Add(t);
        }
        Thread.Sleep(durationMilliseconds);
        Stop();
    }

    /// Signals all running threads to stop and waits for them to terminate.
    public void Stop()
    {
        _running = false;
        foreach (var t in _threads)
        {
            if (t.IsAlive)
                t.Join();
        }
        _threads.Clear();
    }

    private void GenerateLoad(object cpuUsageObject)
    {
        int cpuUsage = (int)cpuUsageObject;

        // Emulate a target CPU load percentage.
        Stopwatch watch = new Stopwatch();

        while (_running)
        {
            watch.Restart();
            while (watch.ElapsedMilliseconds < cpuUsage)
            {
                if (!_running)
                    break;
            }

            if (!_running)
                break;

            int sleepTime = 100 - cpuUsage;
            if (sleepTime > 0)
                Thread.Sleep(sleepTime);
        }
    }
}
'@

Add-Type $code
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

Write-Output "$TestType"
switch ($TestType) {
    "WindowsEvent" { 
        if (-not [System.Diagnostics.EventLog]::SourceExists($Source)) {
            New-EventLog -LogName $LogName -Source ($Source)
        }

        $params = @{
            LogName   = $LogName
            Source    = $Source
            EventID   = $EventID
            EntryType = $EntryType
            Message   = $Message
        }
        Write-Output $params
        Write-EventLog @params
    }

    "Memory" {
        Invoke-MemoryUsage -Duration $Duration
    }

    "CPU" {
        $tester = [CpuTester]::new()
        $tester.Start(90, ([int]$Duration * 1000))
    }
    
    "LogicalDisk" {
        Write-Host $DiskSpacePercentage
        Write-Host $Duration
        Write-Host $ENV:SystemDrive
        Invoke-DiskUsage -RemainingPercentage $DiskSpacePercentage -Duration $Duration -Drive $ENV:SystemDrive
    }
    default {
        throw "Invalid TestType: $TestType"
    }
}