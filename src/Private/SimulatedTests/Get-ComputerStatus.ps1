function Get-ComputerStatus {
    <#
        .SYNOPSIS
            Retrieves the status details of a specified computer.

        .DESCRIPTION
            This function queries the Computers table for name, status, and folder path 
            based on the provided computer name.

        .PARAMETER ComputerName
            The name of the computer to query (case-insensitive).

        .EXAMPLE
            Get-ComputerStatus -ComputerName "COMPUTER1"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )

    try {
        Write-Verbose "Querying computer '$ComputerName' details."
    
        $computerQuery = Invoke-CUQuery -Table Computers -Where "sName='$($ComputerName.ToUpper())'" -Fields sName,Status,FolderPath
        $computer = $computerQuery.Data

        if (-not $computer) { throw "Unable to find computer '$ComputerName'." }

        Write-Verbose "Computer '$ComputerName' details retrieved successfully."
        return $computer
    }
    catch {
        Write-Error "Error in Get-ComputerStatus: $($_.Exception.Message)"
        throw
    }
}