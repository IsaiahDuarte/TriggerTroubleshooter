<#
    .SYNOPSIS
       Helper script for Trigger Troubleshooter Simulations

    .DESCRIPTION
        This script will simulate trigger conditions like creating a windows event.

    .NOTES 
        Version:           1.2.1
        Context:           Made for Trigger Troubleshooter
        Author:            Isaiah Duarte ->  https://github.com/IsaiahDuarte/TriggerTroubleshooter  
        Requires:          The CU Monitor's ControlUp.PowerShell.User.dll & 9.0.5+
        Creation Date:     2/23/2025    
        Updated:           
#>

param (
    [Parameter(Mandatory = $true, ParameterSetName="WindowsEvent")]
    [string] $LogName,

    [Parameter(Mandatory = $true, ParameterSetName="WindowsEvent")]
    [string] $Source,

    [Parameter(Mandatory = $true, ParameterSetName="WindowsEvent")]
    [string] $EventID,

    [Parameter(Mandatory = $true, ParameterSetName="WindowsEvent")]
    [string] $EntryType,
    
    [Parameter(Mandatory = $true, ParameterSetName="WindowsEvent")]
    [string] $Message
)

switch($PsCmdlet.ParameterSetName) {
    "WindowsEvent" { 
        if (-not [System.Diagnostics.EventLog]::SourceExists($Source)) {
            New-EventLog -LogName $LogName -Source ($Source)
        }

        $params = @{
            LogName = $LogName
            Source = $Source
            EventID = $EventID
            EntryType = $EntryType
            Message = $Message
        }
        Write-Host $params
        Write-EventLog @params
    }
}