function Test-ObserverdProperties {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResourceName,

        [Parameter(Mandatory = $true)]
        [string[]] $Properties
    )
   
    Write-Verbose "Starting Test-ObserverdProperties function."
   
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
        
        Write-Verbose "Converting the 'ObserverdProps' JSON string to a PowerShell object."
        $ObserverdProps = $result.Data.ObserverdProps | ConvertFrom-Json -ErrorAction Stop
        
        foreach ($property in $Properties) {
            Write-Verbose "Checking if '$property' is present in ObserverdProps."
            if ($property -notin $ObserverdProps) {
                Write-Verbose "Property '$property' is missing. Returning $false."
                return $false
            }
        }
            
        Write-Verbose "All specified properties were found. Returning $true."
        return $true
    }
    catch {
        Write-Error "An error occurred in Test-ObserverdProperties: $_"
        throw
    }
}