function Invoke-CpuLoad {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 100)]
        [int] $CpuUsage,

        [Parameter(Mandatory = $true)]
        [int] $DurationMilliseconds
    )

    $code = @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading;

public class CpuTester
{
    private volatile bool _running = false;
    private List<Thread> _threads = new List<Thread>();

    /// <summary>
    /// Start generating CPU load.
    /// cpuUsage: an integer between 0 and 100 representing the percentage of CPU load per thread.
    /// durationMilliseconds: how long (in milliseconds) to generate load.
    /// </summary>
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

    /// <summary>
    /// Signals all running threads to stop and waits for them to terminate.
    /// </summary>
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
        Stopwatch watch = new Stopwatch();
        while (_running)
        {
            watch.Restart();
            while (watch.ElapsedMilliseconds < cpuUsage)
            {
                if (!_running)
                    break;
                // Busy work loop to generate load.
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

    if (-not ([System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetType("CpuTester", $false) }))
    {
        Add-Type -TypeDefinition $code -Language CSharp
    }

    $tester = New-Object CpuTester
    try {
        $tester.Start($CpuUsage, $DurationMilliseconds)
        Write-Verbose "CPU load generated at $CpuUsage% for $DurationMilliseconds milliseconds on each processor."
    }
    catch {
        Write-Error $_.Exception.Message
    }
}