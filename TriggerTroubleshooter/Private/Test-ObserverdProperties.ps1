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

    Write-Verbose "Starting Test-ObserverdProperties function."

    # Build query parameters to search for observed properties based on the resource name.
    $splat = @{
        Table  = 'Observables'
        Scheme = 'Runtime'
        Fields = @('ObserverdProps')
        Where  = "ObserverType='DBRecordFieldsObservable' AND Owner='TriggersStore' AND ResourceName='$ResourceName'"
    }

    try {
        Write-Verbose "Executing Invoke-CUQuery with provided parameters."
        $result = Invoke-CUQuery @splat
        Write-Verbose "Invoke-CUQuery executed successfully."

        # Check if any data was returned, if not, then the properties are not observed.
        if ($result.Total -eq 0) {
            Write-Verbose "No data returned from query."
            Write-Warning "Properties are not being observed by monitor."
            return $false
        }

        Write-Verbose "Converting the 'ObserverdProps' JSON string to a PowerShell object."
        $ObserverdProps = $result.Data.ObserverdProps | ConvertFrom-Json -ErrorAction Stop

        # Verify each specified property exists in the observed properties list.
        foreach ($property in $Properties) {
            Write-Verbose "Checking if property '$property' is present in ObserverdProps."
            if ($property -notin $ObserverdProps) {
                Write-Verbose "Property '$property' is missing. Returning \$false."
                return $false
            }
        }

        Write-Verbose "All specified properties were found. Returning \$true."
        return $true
    }
    catch {
        Write-Error "An error occurred in Test-ObserverdProperties: $($_.Exception.Message)"
        throw
    }
} 