function Test-ObserverdProperties {
    <#
        .SYNOPSIS
            Verifies that specified properties are observed by the monitor in the Observables runtime. 

        .DESCRIPTION
            This function executes a query against the 'Observables' table in the 'Runtime' scheme to obtain 
            the observed properties for a given resource. It then verifies that each property provided in the 
            input exists in the observed properties list. If any property is missing, the function returns $false.
            Otherwise, it returns $true.

        .PARAMETER ResourceName
            The name of the resource for which the observed properties should be checked. 

        .PARAMETER Properties
            An array of property names to check for in the observed properties returned from the query.

        .EXAMPLE
            Test-ObserverdProperties -ResourceName "ComputersView" -Properties @("Prop1", "Prop2")
            This checks if "Prop1" and "Prop2" are present in the observed properties for "ComputersView".
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResourceName,

        [Parameter(Mandatory = $true)]
        [string[]] $Properties
    )

    Write-TTLog "Starting Test-ObserverdProperties function."

    $splat = @{
        Table  = 'Observables'
        Scheme = 'Runtime'
        Fields = @('ObserverdProps')
        Where  = "ObserverType='DBRecordFieldsObservable' AND Owner='TriggersStore' AND ResourceName='$ResourceName'"
    }

    try {
        Write-TTLog "Executing Invoke-CUQuery -Table $($splat.Table) -Scheme $($splat.Runtime) -Fields $($splat.Fields) -Where $($splat.Where)"
        $result = Invoke-CUQuery @splat
        Write-TTLog "Invoke-CUQuery executed successfully."

        if ($result.Total -eq 0) {
            Write-TTLog "No data returned from query."
            Write-Warning "Properties are not being observed by monitor."
            return $false
        }

        Write-TTLog "Converting the 'ObserverdProps' JSON string to a PowerShell object."
        Write-TTLog "JSON: $($result.Data.ObserverdProps)"
        $ObserverdProps = $result.Data.ObserverdProps | ConvertFrom-Json -ErrorAction Stop

        foreach ($property in $Properties) {
            Write-TTLog "Checking if property '$property' is present in ObserverdProps."
            if ($property -notin $ObserverdProps) {
                Write-TTLog "Property '$property' is missing. Returning \$false."
                return $false
            }
        }

        Write-TTLog "All specified properties were found. Returning \$true."
        return $true
    }
    catch {
        Write-TTLog "ERROR: $($_.Exception.Message)"
        Write-Error "An error occurred in Test-ObserverdProperties: $($_.Exception.Message)"
        throw
    }
} 