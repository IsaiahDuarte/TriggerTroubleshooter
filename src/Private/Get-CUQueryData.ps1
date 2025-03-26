function Get-CUQueryData {
    <#
        .SYNOPSIS
            Retrieves data from a specified table using invoke-cuquery.

        .DESCRIPTION
            This function queries a data source by using invoke-cuquery. 

        .PARAMETER Table
            The name of the table to query.

        .PARAMETER Fields
            An array of field names to retrieve.

        .PARAMETER Where
            A filter expression for Invoke-CUQuery.

        .PARAMETER TakeAll
            Takes all records available

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

    Write-TTLog "Starting Get-CUQueryData function."
    $splat = @{
        Table  = $Table
        Fields = $Fields
        Where  = $Where
    }
    try {
        if ($TakeAll) {
            Write-TTLog "TakeAll passed, getting record count"
            $splat.Take = 1
            $count = (Invoke-CUQuery @splat).Total

            Write-TTLog "There are $count records"
            $splat.Take = $count
        }
        else {
            $splat.Take = $Take
        }

        Write-TTLog "Executing Invoke-CUQuery with provided parameters."
        $invokeResult = Invoke-CUQuery @splat
        Write-TTLog "Invoke-CUQuery executed successfully. Processing returned data."
        Write-TTLog "Returning the retrieved data."
        return , $invokeResult.Data
    }
    catch {
        Write-TTLog "ERROR: $($_.Exception.Message)"
        Write-Error "An error occurred in Get-CUQueryData: $($_.Exception.Message)"
        throw
    }
}