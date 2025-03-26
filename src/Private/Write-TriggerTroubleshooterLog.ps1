function Write-TTLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Message,

        [switch] $ToFile,
        [switch] $ToHost
    )

    $caller = "<unknown>"
    $callStack = Get-PSCallStack
    if ($callStack.Count -gt 1) {
        $caller = $callStack[1].FunctionName
    }

    $timestamp = Get-Date -Format "o"
    $logMessage = "$timestamp [$caller] $Message"

    $shouldLogToFile = $ToFile.IsPresent -or ($env:TRIGGER_TROUBLESHOOTER_LOG_TO_FILE -eq $true)
    $shouldLogToHost = $ToHost.IsPresent -or ($env:TRIGGER_TROUBLESHOOTER_LOG_TO_HOST -eq $true)

    if ($shouldLogToFile) {
        $logFile = Join-Path $env:TEMP "trigger_troubleshooter.log"
        try {
            Add-Content -Path $logFile -Value $logMessage
        }
        catch {
            Write-Warning "Failed to write to $logFile. Error: $_"
        }
    }

    if ($shouldLogToHost) {
        Write-Host $logMessage
    }

    if (-not $shouldLogToFile -and -not $shouldLogToHost) {
        Write-Verbose $logMessage
    }
}