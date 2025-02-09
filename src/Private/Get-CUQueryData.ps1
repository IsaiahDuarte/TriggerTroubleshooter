function Get-CUQueryData {
    <#
        .SYNOPSIS
            Retrieves data from a specified table using either export-cuquery or invoke-cuquery. 

        .DESCRIPTION
            This function queries a data source by either exporting the results to a JSON file and reading it back
            (using export-cuquery) or by directly using invoke-cuquery. When using invoke-cuquery, it uses the
            provided 'Take' parameter to limit the number of records.

        .PARAMETER Table
            The name of the table to query.

        .PARAMETER Fields
            An array of field names to retrieve.

        .PARAMETER Where
            A filter expression for Invoke-CUQuery.

        .PARAMETER UseExport
            A switch used to get data using export-cuquery.

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

        [Parameter(Mandatory = $false, ParameterSetName = "UseExport")]
        [switch] $UseExport,

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
        if ($PSCmdlet.ParameterSetName -eq "UseExport" -and $UseExport) {
            Write-Verbose "UseExport is set to TRUE. Proceeding with export method."

            Write-Verbose "Generating temporary file and directory."
            $tempFile = "$(([guid]::NewGuid().ToString("N"))).json"
            $dir = $env:TEMP
            $fullPath = Join-Path -Path $dir -ChildPath $tempFile
            Write-Verbose "Full path for export: $fullPath"

            $splat.OutputFolder = $dir
            $splat.FileName = $tempFile
            $splat.FileFormat = "Json"

            Write-Verbose "Executing Export-CUQuery with provided parameters."
            Export-CUQuery @splat | Out-Null
            Write-Verbose "Export-CUQuery executed successfully. Reading exported data from $fullPath."

            Write-Verbose "Converting exported JSON data to PowerShell objects."
            $json = Get-Content $fullPath -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop

            [Object[]] $results = $json | ForEach-Object {
                $obj = @{ Key = $_.RecordId }

                foreach ($property in $_.Properties) {
                    # Check for non-null values and assign the key's value accordingly.
                    if ($null -ne $property.Value) {
                        $obj[$property.PropertyName] = $property.Value.InnerValue
                        continue
                    }

                    if ($null -ne $property.InnerValue.fAvarageValue) {
                        $obj[$property.PropertyName] = $property.InnerValue.fAvarageValue
                        continue
                    }

                    if ($null -ne $property.InnerValue) {
                        $obj[$property.PropertyName] = $property.InnerValue
                        continue
                    }
                }

                [PSCustomObject] $obj
            }

            Write-Verbose "Successfully converted JSON data. Processing records."

            Write-Verbose "Removing temporary file at $fullPath."
            Remove-Item -Path $fullPath -Force -ErrorAction Stop
            Write-Verbose "Temporary file removed successfully."

            Write-Verbose "Returning the processed export results."
            return ,$results
        }
        elseif ($PSCmdlet.ParameterSetName -eq "Take") {
            $splat.Take = $Take
            Write-Verbose "Executing Invoke-CUQuery with provided parameters."
            $invokeResult = Invoke-CUQuery @splat
            Write-Verbose "Invoke-CUQuery executed successfully. Processing returned data."

            Write-Verbose "Returning the retrieved data."
            return ,$invokeResult.Data
        }
    }
    catch {
        Write-Error "An error occurred in Get-CUQueryData: $($_.Exception.Message)"
        throw
    }
} 