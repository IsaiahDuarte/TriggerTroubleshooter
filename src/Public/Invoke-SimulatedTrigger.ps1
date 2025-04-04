function Invoke-SimulatedTrigger {
    <#
    .SYNOPSIS
        Invokes a simulated trigger of a given type (CPU, Memory, WindowsEvent, or DiskUsage).

    .DESCRIPTION
        This function checks a computer's status, retrieves an existing reference trigger,
        and uses the trigger definition to build a new "simulated" trigger for testing.
        It then invokes a matching script action (Trigger Troubleshooter - Simulated Test)
        to ensure the new trigger actually fires as expected.

    .PARAMETER ComputerName
        The name of the target computer/server.

    .PARAMETER TriggerName
        The name of the existing reference trigger to clone/modify.

    .PARAMETER ConditionType
        One of CPU, Memory, WindowsEvent, DiskIO, or DiskUsage.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ComputerName,

        [Parameter(Mandatory = $true)]
        [string] $TriggerName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("CPU", "Memory", "WindowsEvent", "DiskUsage", "DiskIO")]
        [string] $ConditionType
    )

    # Configurations for each type of simulated test
    $conditionConfigs = @{
        CPU          = @{
            Validate                = @{
                TriggerTypeExpected = "Machine Stress"
                TableNameExpected   = "Computers"
                ErrorMessage        = "Trigger '$TriggerName' is not an Advanced Machine Trigger."
            }
            TriggerNamePrefix       = "TT-Simulated-CPUUsage"
            TriggerType             = "Advanced"
            AdvancedTriggerSettings = @{ TriggerStressRecordType = "Machine" }
            Timeout                 = 1
            BuildActionParams       = {
                return (@{ arg_0 = "CPU"; arg_6 = 15 } | ConvertTo-Json)
            }
        }

        Memory       = @{
            Validate                = @{
                TriggerTypeExpected = "Machine Stress"
                TableNameExpected   = "Computers"
                ErrorMessage        = "Trigger '$TriggerName' is not an Advanced Machine Trigger."
            }
            TriggerNamePrefix       = "TT-Simulated-MemoryUsage"
            TriggerType             = "Advanced"
            AdvancedTriggerSettings = @{ TriggerStressRecordType = "Machine" }
            Timeout                 = 1
            BuildActionParams       = {
                return (@{ arg_0 = "Memory"; arg_6 = 6 } | ConvertTo-Json)
            }
        }

        WindowsEvent = @{
            Validate          = @{
                TriggerTypeExpected = "Windows Event"
                TableNameExpected   = $null
                ErrorMessage        = "Trigger '$TriggerName' is not a Windows Event Trigger."
            }
            TriggerNamePrefix = "TT-Simulated-WindowsEvent"
            TriggerType       = "WindowsEvent"
            Timeout           = 30
            BuildActionParams = {
                param($NodeData)
                $entryTypeMapping = @{ 1 = "Error"; 2 = "Information"; 3 = "Warning" }
                return (@{
                        arg_0 = "WindowsEvent"
                        arg_1 = $NodeData.Log
                        arg_2 = $NodeData.Source
                        arg_3 = $NodeData.EventID
                        arg_4 = $entryTypeMapping[$NodeData.EntryType]
                        arg_5 = $NodeData.Message
                        arg_6 = 30
                    } | ConvertTo-Json)
            }
        }

        DiskUsage    = @{
            Validate                = @{
                TriggerTypeExpected = "Logical Disk Stress"
                TableNameExpected   = $null
                ErrorMessage        = "Trigger '$TriggerName' is not a LogicalDisk Trigger."
            }
            TriggerNamePrefix       = "TT-Simulated-DiskUsage"
            TriggerType             = "Advanced"
            AdvancedTriggerSettings = @{ TriggerStressRecordType = "LogicalDisk" }
            Timeout                 = 1
            BuildActionParams       = {
                param($NodeData)
                return (@{
                        arg_0 = "DiskUsage"
                        arg_6 = 10
                        arg_7 = $NodeData.FreeSpacePercentage
                    } | ConvertTo-Json)
            }
        }

        DiskIO       = @{
            Validate                = @{
                TriggerTypeExpected = "Logical Disk Stress"
                TableNameExpected   = $null
                ErrorMessage        = "Trigger '$TriggerName' is not a LogicalDisk Trigger."
            }
            TriggerNamePrefix       = "TT-Simulated-DiskIO"
            TriggerType             = "Advanced"
            AdvancedTriggerSettings = @{ TriggerStressRecordType = "LogicalDisk" }
            Timeout                 = 1
            BuildActionParams       = {
                param($NodeData)
                return (@{
                        arg_0 = "DiskIO"
                        arg_6 = 15
                        arg_7 = $NodeData.FreeSpacePercentage
                    } | ConvertTo-Json)
            }

        }
    }

    $newTrigger = $null
    $newTriggerName = $null

    $config = $conditionConfigs[$ConditionType]
    if (-not $config) {
        throw "Unsupported ConditionType '$ConditionType'."
    }

    try {
        Write-TTLog "Checking computer status."
        $computer = Get-ComputerStatus -ComputerName $ComputerName
        if ($computer.Status -ne "Ready") {
            throw "Status for '$ComputerName' is '$($computer.Status)' instead of 'Ready'."
        }

        Write-TTLog "Retrieving trigger '$TriggerName'."
        $trigger = Get-Trigger -Name $TriggerName -Fields @("Name", "Id", "TriggerType", "TableName")
        if (-not $trigger) {
            Write-Warning "Trigger '$TriggerName' not found."
            return
        }

        # Check the expected TriggerType / TableName from the config
        $expectedType = $config.Validate.TriggerTypeExpected
        $expectedTable = $config.Validate.TableNameExpected
        if ($null -ne $expectedType -and $trigger.TriggerType -ne $expectedType) {
            Write-Warning $config.Validate.ErrorMessage
            throw "Invalid Trigger Type"
        }
        if ($null -ne $expectedTable -and $trigger.TableName -ne $expectedTable) {
            Write-Warning $config.Validate.ErrorMessage
            throw "Invalid Trigger Table"
        }

        Write-TTLog "Retrieving trigger details."
        $details = Get-CUTriggerDetails -TriggerId $trigger.ID

        # Rebuild the root node
        $rootNode = [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]::New()
        $rootNode.ChildNodes = $details.FilterNodes

        # Get matching condition
        Write-TTLog "Finding matching condition for '$ConditionType'."
        switch ($ConditionType) {
            "CPU" { $node = Get-MatchingCPUCondition -RootNode $rootNode }
            "Memory" { $node = Get-MatchingMemoryCondition -RootNode $rootNode }
            "WindowsEvent" { $node = Get-MatchingWindowsEvent -RootNode $rootNode }
            "DiskUsage" { $node = Get-MatchingDiskUsageCondition -RootNode $rootNode }
            "DiskIO" { $node = Get-MatchingDiskIOCondition -RootNode $rootNode }
        }

        if (-not $node) {
            Write-Warning "No node data was returned. Cannot proceed."
            return
        }

        # Build the new trigger
        $newTriggerName = $config.TriggerNamePrefix + "-" + [guid]::NewGuid()
        Write-TTLog "Preparing new trigger info for '$newTriggerName'."

        $rootFolder = (Invoke-CUQuery -Table Folders -Where "FolderType=4" -Fields Path).Data
        if (-not $rootFolder) { throw "Unable to find Root Folder." }

        $newTriggerSplat = @{
            TriggerName        = $newTriggerName
            Description        = "Generated by TriggerTroubleshooter"
            IncidentScheduleId = "All days"
            Scope              = @{
                ExcludedFolders = $rootFolder.Path
                IncludedFolders = $computer.FolderPath
            }
            FilterNodes        = $node.Node.ChildNodes
            TriggerType        = $config.TriggerType
        }

        # For advanced triggers, add advanced properties
        if ($config.ContainsKey('AdvancedTriggerSettings')) {
            $newTriggerSplat.AdvancedTriggerSettings = $config.AdvancedTriggerSettings
        }

        # Windows Event expects ComputerDownProperties running 9.0.0-9.0.5
        if ($ConditionType -eq "WindowsEvent") {
            $ModuleVersion = Get-Module -Name ControlUp.PowerShell.User
            if ($ModuleVersion.Version.Minor -eq 0 -and $ModuleVersion.Version.Major -eq 9) {
                $newTriggerSplat.ComputerDownProperties = @{}
            }
        }

        # Prep arguments
        $actionParams =
        if ($config.BuildActionParams.Ast.ParamBlock.Parameters.Count -gt 0) {
            $config.BuildActionParams.Invoke($node.Data)
        }
        else {
            $config.BuildActionParams.Invoke()
        }

        # Build/test trigger
        $timeout = $config.Timeout
        $triggerParams = @{
            NewTriggerProps = $newTriggerSplat
            Computer        = $computer
            TriggerName     = $newTriggerName
            ActionParams    = $actionParams
            Timeout         = $timeout
        }
        
        $createResult = New-SimulatedTrigger @triggerParams
        $newTrigger = $createResult.TriggerObject
        $didTriggerFire = $createResult.Fired

        return [pscustomobject] @{
            TriggerFired = $didTriggerFire
        }
    }
    catch {
        Write-TTLog "ERROR: $($_.Exception.Message)"
        Write-Error "Error in Invoke-SimulatedTrigger: $($_.Exception.Message)"
        throw
    }
    finally {
        if ($newTrigger -and $newTrigger.TriggerId) {
            Write-TTLog "Removing simulated trigger '$newTriggerName'."
            Remove-CUTrigger -TriggerId $newTrigger.TriggerId | Out-Null
            Wait-ForTrigger -TriggerName $newTriggerName | Out-Null
        }
    }
}