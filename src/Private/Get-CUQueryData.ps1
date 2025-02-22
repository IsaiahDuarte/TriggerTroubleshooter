function Get-CUQueryData {
    <#
        .SYNOPSIS
            Retrieves data from a specified table using either export-cuquery or invoke-cuquery.

        .DESCRIPTION
            This function queries a data source by using invoke-cuquery. 

        .PARAMETER Table
            The name of the table to query.

        .PARAMETER Fields
            An array of field names to retrieve.

        .PARAMETER Where
            A filter expression for Invoke-CUQuery.

        .PARAMETER TakeAll
            The maximum number of records to retrieve. Defaults to 100.

        .PARAMETER Take
            The maximum number of records to retrieve. Defaults to 100.

        .EXAMPLE
            Get-CUQueryData -Table "MyTable" -Fields @("Field1", "Field2") -Where "Field1='value'" -Take 50
    #>
    [CmdletBinding(DefaultParameterSetName = "Take")]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Table,

        [Parameter(Mandatory = $true)]
        [string[]] $Fields,

        [Parameter(Mandatory = $true)]
        [string] $Where,

        [Parameter(Mandatory = $false, ParameterSetName = "TakeAll")]
        [switch] $TakeAll,

        [Parameter(Mandatory = $false, ParameterSetName = "Take")]
        [int] $Take = 100
    )

    Write-Verbose "Starting Get-CUQueryData function."
    $splat = @{
        Table  = $Table
        Fields = $Fields
        Where  = $Where
    }
    try {
        if ($TakeAll) {
            Write-Verbose "TakeAll passed, getting record count"
            $splat.Take = 1
            $count = (Invoke-CUQuery @splat).Total

            Write-Verbose "There are $count records"
            $splat.Take = $count
        } else {
            $splat.Take = $Take
        }

        Write-Verbose "Executing Invoke-CUQuery with provided parameters."
        $invokeResult = Invoke-CUQuery @splat
        Write-Verbose "Invoke-CUQuery executed successfully. Processing returned data."
        Write-Verbose "Returning the retrieved data."
        return ,$invokeResult.Data
    }
    catch {
        Write-Error "An error occurred in Get-CUQueryData: $($_.Exception.Message)"
        throw
    }
}