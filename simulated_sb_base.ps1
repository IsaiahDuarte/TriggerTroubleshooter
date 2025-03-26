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
        Links:
        Updated:           
#>

param (
    [Parameter(Mandatory = $true)]
    [string] $TestType,

    [Parameter(Mandatory = $false)]
    [string] $LogName,

    [Parameter(Mandatory = $false)]
    [string] $Source,

    [Parameter(Mandatory = $false)]
    [string] $EventID,

    [Parameter(Mandatory = $false)]
    [string] $EntryType,
    
    [Parameter(Mandatory = $false)]
    [string] $Message,
    
    [Parameter(Mandatory = $false)]
    [string] $Duration,

    [Parameter(Mandatory = $false)]
    [string] $DiskSpacePercentage
)
###ImportModule###
Write-Output "$TestType"
switch ($TestType) {
    "WindowsEvent" { 
        if (-not [System.Diagnostics.EventLog]::SourceExists($Source)) {
            New-EventLog -LogName $LogName -Source ($Source)
        }

        $params = @{
            LogName   = $LogName
            Source    = $Source
            EventID   = $EventID
            EntryType = $EntryType
            Message   = $Message
        }
        Write-Output $params
        Write-EventLog @params
    }

    "Memory" {
        Invoke-MemoryUsage -Duration $Duration
    }

    "CPU" {
        Invoke-CpuLoad -CPUUsage 90 -DurationInMilliseconds 1000
    }
    
    "DiskUsage" {
        Write-Host $DiskSpacePercentage
        Write-Host $Duration
        Write-Host $ENV:SystemDrive
        Invoke-DiskUsage -RemainingPercentage $DiskSpacePercentage -Duration $Duration -Drive $ENV:SystemDrive
    }
    default {
        throw "Invalid TestType: $TestType"
    }
}