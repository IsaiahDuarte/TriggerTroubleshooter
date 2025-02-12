function Get-IdentityPropertyFromTable {
        <#
        .SYNOPSIS
            Gets a readable field from a given table.
        .DESCRIPTION
            This function will take a table name and provide a field that can be interperted by the user.
        .PARAMETER Table
            The name of the table to query.
        .EXAMPLE
            Get-IdentityPropertyFromTable -Table "MyTable"
    #>

    param(
        [Parameter(Mandatory=$false)]
        [string] $Table
    )

    switch ($Table) {
        "SessionsView" { return "sUserAccount" }
        "ComputerView" { return "sName" }
        "Folders" { return "Name" }
        "Processes" { return "sName" }
        "Services" { return "ServiceDisplayName" }
        "AccountsView" { return "Account" }
        "ProcessGroups" { return "Name" }
        "Hosts" { return "Name" }
        "Datastores" { return "DatastoreName" }
        "Datastores on Hosts" { return "DatastoreName" }
        "vDisks" { return "vDiskFileName" }
        "LogicalDisks" { return "Computer" }
        "FsLogixDisks" { return "FsLogixDiskPath" }
        "NetScalers" { return "NetScalerName" }
        "LoadBalancers" { return "LoadBalancerName" }
        "LBServiceGroups" { return "LBServiceGroupName" }
        "LBServices" { return "ServiceLBName" }
        "Gateways" { return "GatewayName" }
        "NICs" { return "NICNetScalerName" }
        "STAs" { return "STAName" }
        "Citrix Licenses" { return "ComputerName" }
        "AvdHostPools" { return "AzResourceGroup" }
        "AvdWorkspaces" { return "AvdWorkspaceFriendlyName" }
        "AvdApplicationGroups" { return "Name" }
        default { return "" }
    }
}