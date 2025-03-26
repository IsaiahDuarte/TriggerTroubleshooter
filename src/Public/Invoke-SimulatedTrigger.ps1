function Invoke-SimulatedTrigger {
    <#
    .SYNOPSIS
        Invokes a simulated trigger of a given type (CPU, Memory, WindowsEvent, or DiskUsage).

    .DESCRIPTION
        This function checks a computer's status, retrieves an existing reference trigger,
        and uses the trigger definition to build a new "simulated" trigger for testing.
        It then invokes a matching script action (Trigger Troubleshooter - Simulated Test)
        to ensure the new trigger actually fires as expected. Finally, it cleans up
        by removing the temporary test trigger.

    .PARAMETER ComputerName
        The name of the target computer/server.

    .PARAMETER TriggerName
        The name of the existing reference trigger to clone/modify.

    .PARAMETER ConditionType
        One of CPU, Memory, WindowsEvent, or DiskUsage.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ComputerName,

        [Parameter(Mandatory = $true)]
        [string] $TriggerName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("CPU", "Memory", "WindowsEvent", "DiskUsage")]
        [string] $ConditionType
    )

    # ----------------------------------------------------------------------
    # 1) Centralized Condition Config
    # ----------------------------------------------------------------------
    # This hashtable contains all per-condition logic in one place:
    #  - The expected trigger type or table name for validation.
    #  - The new trigger's name prefix.
    #  - The final 'TriggerType' or 'AdvancedTriggerSettings' needed for Add-CUTrigger.
    #  - A script block to build your -UserInput JSON for the script action.
    #  - A default timeout for waiting on the new trigger to fire.
    # ----------------------------------------------------------------------
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
            # No advanced settings needed
            Timeout           = 30
            BuildActionParams = {
                # Windows Event might need detail from the matched node's Data
                # We'll fill this in after we call the relevant "Get-MatchingWindowsEvent" function
                param($NodeData)
                $entryTypeMapping = @{ 1 = "Error"; 2 = "Information"; 3 = "Warning" }
                return (@{
                        arg_0 = "WindowsEvent"
                        arg_1 = $NodeData.Log
                        arg_2 = $NodeData.Source
                        arg_3 = $NodeData.EventID
                        arg_4 = $entryTypeMapping[$NodeData.EntryType]
                        arg_5 = $NodeData.Message
                        arg_6 = 30  # The time to keep the event around
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
                        arg_6 = 10      # seconds or threshold for activity
                        arg_7 = $NodeData.FreeSpacePercentage
                    } | ConvertTo-Json)
            }
        }
    }

    # Pull the relevant config block based on ConditionType
    $config = $conditionConfigs[$ConditionType]
    if (-not $config) {
        throw "Unsupported ConditionType '$ConditionType'."
    }

    # Used to store the newly added trigger object (so we can remove it in finally{})
    $newTrigger = $null
    $newTriggerName = $null


    try {
        # ------------------------------------------------------------------
        # CHECK COMPUTER STATUS
        # ------------------------------------------------------------------
        Write-TTLog "Checking computer status."
        $computer = Get-ComputerStatus -ComputerName $ComputerName
        if ($computer.Status -ne "Ready") {
            throw "Status for '$ComputerName' is '$($computer.Status)' instead of 'Ready'."
        }

        # ------------------------------------------------------------------
        # VALIDATE REFERENCE TRIGGER
        # ------------------------------------------------------------------
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

        # ------------------------------------------------------------------
        # RETRIEVE TRIGGER DETAILS / MATCHING NODE
        # ------------------------------------------------------------------
        Write-TTLog "Retrieving trigger details."
        $details = Get-CUTriggerDetails -TriggerId $trigger.ID

        # Rebuild the root node object from $details
        $rootNode = [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]::New()
        $rootNode.ChildNodes = $details.FilterNodes

        # Based on ConditionType, call the relevant "Get-MatchingX" function
        Write-TTLog "Finding matching condition for '$ConditionType'."
        switch ($ConditionType) {
            "CPU" { $node = Get-MatchingCPUCondition -RootNode $rootNode }
            "Memory" { $node = Get-MatchingMemoryCondition -RootNode $rootNode }
            "WindowsEvent" { $node = Get-MatchingWindowsEvent -RootNode $rootNode }
            "DiskUsage" { $node = Get-MatchingDiskUsageCondition -RootNode $rootNode }
        }

        if (-not $node) {
            Write-Warning "No node data was returned. Cannot proceed."
            return
        }

        # ------------------------------------------------------------------
        # BUILD NEW TRIGGER SPLAT
        # ------------------------------------------------------------------
        $newTriggerName = $config.TriggerNamePrefix + "-" + [guid]::NewGuid()
        Write-TTLog "Preparing new trigger info for '$newTriggerName'."

        # Root folder used for ExcludedFolders, etc.
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

        # Windows Event special case if running 9.0.5
        if ($ConditionType -eq "WindowsEvent") {
            $ModuleVersion = Get-Module -Name ControlUp.PowerShell.User
            if ($ModuleVersion.Version.Minor -eq 0 -and $ModuleVersion.Version.Major -eq 9) {
                $newTriggerSplat.ComputerDownProperties = @{}
            }
        }

        # ------------------------------------------------------------------
        # CREATE TRIGGER + INVOKE ACTION + WAIT FOR FIRING
        # ------------------------------------------------------------------
        # Build action params (some conditions just have a script block that returns JSON)
        # For WindowsEvent or DiskUsage, we need to pass the node.Data to that script block.
        $actionParams =
        if ($config.BuildActionParams.Ast.ParamBlock.Parameters.Count -gt 0) {
            # If the script block has a param($NodeData), pass $node.Data
            $config.BuildActionParams.Invoke($node.Data)
        }
        else {
            $config.BuildActionParams.Invoke()
        }

        $timeout = $config.Timeout
        $createResult = New-SimulatedTrigger -NewTriggerProps $newTriggerSplat `
            -Computer      $computer `
            -TriggerName   $newTriggerName `
            -ActionParams  $actionParams `
            -Timeout       $timeout
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
        # ------------------------------------------------------------------
        # CLEAN UP THE NEWLY CREATED TRIGGER
        # ------------------------------------------------------------------
        if ($newTrigger -and $newTrigger.TriggerId) {
            Write-TTLog "Removing simulated trigger '$newTriggerName'."
            Remove-CUTrigger -TriggerId $newTrigger.TriggerId | Out-Null
            Wait-ForTrigger -TriggerName $newTriggerName | Out-Null
        }
    }
}