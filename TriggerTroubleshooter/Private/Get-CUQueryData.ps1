function Get-CUQueryData {
    [CmdletBinding(DefaultParameterSetName="Take")]
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
            Write-Verbose "Full Path $fullPath"

            Write-Verbose "Updating splat hashtable with export parameters."
            $splat.OutputFolder = $dir
            $splat.FileName       = $tempFile
            $splat.FileFormat     = "Json"

            Write-Verbose "Executing Export-CUQuery with provided parameters."
            Export-CUQuery @splat | Out-Null
            Write-Verbose "Export-CUQuery executed successfully. Reading exported data from $fullPath."

            Write-Verbose "Converting exported JSON data to PowerShell objects."
            $json = Get-Content $fullPath -ErrorAction Stop  | ConvertFrom-Json -ErrorAction Stop

            $results = $json  | ForEach-Object {
                $obj = @{
                    Key = $_.RecordId
                }
         
                foreach ($property in $_.Properties) {
                    if($null -ne $property.Value) {
                        $obj[$property.PropertyName] = $property.Value.InnerValue
                        continue
                    }

                    if($null -ne $property.InnerValue.fAvarageValue) {
                        $obj[$property.PropertyName] = $property.InnerValue.fAvarageValue
                        continue
                    } 

                    if($null -ne $property.InnerValue) {
                        $obj[$property.PropertyName] = $property.InnerValue
                        continue
                    }
                }
         
                [PSCustomObject]$obj
            }
            Write-Verbose "Successfully converted JSON data. Processing records."

            Write-Verbose "Removing temporary file at $fullPath."
            Remove-Item -Path $fullPath -Force -ErrorAction Stop
            Write-Verbose "Temporary file removed successfully."

            Write-Verbose "Returning the processed results."
            return $results
        }
        elseif ($PSCmdlet.ParameterSetName -eq "Take") {
            $splat.Take = $Take
            Write-Verbose "Executing Invoke-CUQuery with provided parameters."
            $invokeResult = Invoke-CUQuery @splat
            Write-Verbose "Invoke-CUQuery executed successfully. Retrieving data."

            Write-Verbose "Returning the retrieved data."
            return $invokeResult.Data
        }
    }
    catch {
        Write-Error "An error occurred in Get-CUQueryData: $_"
        throw
    }
}