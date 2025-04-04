function Find-ExePath {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    # Try using Get-Command
    try {
        $cmd = Get-Command $Name -ErrorAction Stop
        return $cmd.Source
    }
    catch {
        # Not found using Get-Command – try where.exe
        Write-Verbose "Get-Command did not find $Name. Trying where.exe..."
        $whereResult = where.exe $Name 2>$null
        if ($whereResult) {
            # where.exe might return multiple matches, so take the first valid one
            foreach ($path in $whereResult) {
                if (Test-Path $path) {
                    return $path
                }
            }
        }

        Write-Verbose "where.exe did not find $Name. Trying registry search 'App Paths'..."
        # Try registry lookup in "App Paths"
        $regPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$Name",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$Name"
        )
        foreach ($regPath in $regPaths) {
            if (Test-Path $regPath) {
                $exePath = (Get-ItemProperty -Path $regPath).'(default)'
                if (Test-Path $exePath) {
                    return $exePath
                }
            }
        }
    }
    return $null
}
