function New-NodeDataTemplate {
    param(
        [Parameter(Mandatory)]
        [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode] $RootNode,
        [Parameter(Mandatory)]
        [string[]] $ColumnsToKeep,
        [Parameter(Mandatory)]
        [ScriptBlock] $BoundaryCheck,
        [Parameter(Mandatory)]
        [hashtable] $Defaults
    )

    Write-TTLog "Santizing node"
    $sanitizedRoot = Format-SimulationNode -Node $RootNode -Columns $ColumnsToKeep
    if (-not $sanitizedRoot) {
        Write-Warning "No triggers remain after sanitization."
        return $null
    }

    Write-TTLog "Getting constraints"
    $constraints = Get-ConstraintsForNode -Node $sanitizedRoot

    
    $data = [PSCustomObject] $Defaults

    foreach ($key in $constraints.Keys) {
        $data | Add-Member -NotePropertyName $key -NotePropertyValue $constraints[$key] -Force
    }

    Write-TTLog "Performing BoundaryCheck on node"
    # Invoke returns a System.Collections.ObjectModel.Collection[psobject]
    $sanitizedRoot = $BoundaryCheck.Invoke($data,$sanitizedRoot)[0]

    Write-TTLog "Removing empty nodes"
    $sanitizedRoot = Remove-EmptyNodes -Node $sanitizedRoot

    return ,[PSCustomObject]@{
        Data = $data
        Node = $sanitizedRoot
    }
}