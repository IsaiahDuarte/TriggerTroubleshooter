function Set-WindowsEventData {
    <#
        .SYNOPSIS
            Maps the EntryType to a string
        .DESCRIPTION
            The Events database stores the EntryType as a int but in the trigger we comapre by string
        .PARAMETER Data
            Expecting output from Get-CUQueryData.
        .EXAMPLE
            Set-WindowsEventData
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]] $Data
    )

    try {
        $properties = $Data | Get-Member -MemberType NoteProperty

        if($properties.Name -notcontains "EntryType") {
            Write-TriggerTroubleshooterLog "No need to adjust Windows Event Data, EntryTye is NOT a property"
            return $Data
        }

        foreach($wEvent in $Data) {
            switch($wEvent.EntryType) {
                2 {
                    $wEvent.EntryType = "Warning"
                }

                1 {
                    $wEvent.EntryType = "Error"
                }

                default { throw "Invalid EntryType" }
            }
        }

        return $Data
    }
    catch {
        Write-TriggerTroubleshooterLog "ERROR: $($_.Exception.Message)"
        throw "Error in Set-WindowsEventData: $($_.Exception.Message)"
    }
} 