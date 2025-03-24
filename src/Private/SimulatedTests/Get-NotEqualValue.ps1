function Get-NotEqualValue {
    <#
    .SYNOPSIS
        Generates a distinct value not equal to the specified compareValue.
    
    .DESCRIPTION
        This function returns a value that is different from the given compareValue.
        For numeric values, it returns compareValue + 1; for strings, it appends "_NOT".
    
    .PARAMETER columnName
        A string representing the column name (for context; not used in value generation).
    
    .PARAMETER compareValue
        The value to compare against.
    
    .EXAMPLE
        PS C:\> Get-NotEqualValue -columnName "Age" -compareValue 5
        6
    #>
    
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $columnName,
    
        [Parameter(Mandatory = $true)]
        [object] $compareValue
    )
    
    try {
        Write-TriggerTroubleshooterLog "Determining distinct value for compareValue: $compareValue"
    
        # Check if compareValue can be treated as a number
        if ($compareValue -as [double]) {
            $result = ([double]$compareValue + 1)
            Write-TriggerTroubleshooterLog "Numeric value detected. Returning $compareValue + 1 = $result"
            return $result
        }
    
        # Otherwise assume it's a string
        $result = "$compareValue" + "_NOT"
        Write-TriggerTroubleshooterLog "Non-numeric value detected. Returning '$result'"
        return $result
    }
    catch {
        Write-Error "Error in Get-NotEqualValue: $($_.Exception.Message)"
        throw
    }
}