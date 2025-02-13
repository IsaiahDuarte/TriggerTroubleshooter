BeforeAll {
    # Load the module under test
    $modulePath = $PSCommandPath.Replace("\tests\integration\Public\Test-Trigger.Tests.ps1", "\src\TriggerTroubleshooter.psm1")
    Import-Module $modulePath -Force
    # Load the latest version of ControlUp.PowerShell.User.dll
    $programFiles = [Environment]::GetEnvironmentVariable("ProgramW6432")
    $userModulePath = Join-Path -Path $programFiles -ChildPath "\Smart-X\ControlUpMonitor\*\ControlUp.PowerShell.User.dll"
    $latestUserModulePath = (Get-ChildItem $userModulePath -Recurse | Sort-Object LastWriteTime -Descending)[0]
    Import-Module $latestUserModulePath
    $script:testTriggerBase = 'TriggerTroulbeshooter-Integration-'

    function Add-TestCUTrigger {
        param (
            [hashtable]$TriggerDefinition
        )

        $triggerName = "$($script:testTriggerBase)$($TriggerDefinition.Suffix)"
    
        $existingTrigger = (Invoke-CUQuery -Scheme 'Config' -Table 'TriggersConfiguration' `
                -Fields @("Name", "Id") -Where "Name='$triggerName'")
        if ($existingTrigger.Total -gt 0) {
            Remove-CUTrigger -TriggerId $existingTrigger.Data.Id | Out-Null
            Wait-ForTrigger -TriggerName $triggerName | Out-Null
        }
        
        $splat = @{
            TriggerName             = $triggerName
            TriggerType             = "Advanced"
            AdvancedTriggerSettings = @{ TriggerStressRecordType = $TriggerDefinition.RecordType }
            IncidentScheduleId      = "Weekdays"
            FilterNodes             = @{
                LogicalOperator      = 'And'
                IsNegation           = $false
                ExpressionDescriptor = $TriggerDefinition.FilterDescriptor
            }
        }
        Add-CUTrigger @splat | Out-Null
        
        return , $triggerName
    }
    
    function Wait-ForTrigger {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [string]$TriggerName,
            [int]$TimeoutSeconds = 30,
            [int]$PollIntervalSeconds = 2,
            [Switch]$ShouldExist
        )
    
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
        do {
            $queryResult = (Invoke-CUQuery -Scheme 'Config' -Table 'TriggersConfiguration' `
                    -Fields @("Name", "Id") -Where "Name='$TriggerName'")
            Start-Sleep -Seconds $PollIntervalSeconds
            if ($ShouldExist) {
                if ($queryResult.Total -gt 0) { return $queryResult.Data }
            }
            else {
                if ($queryResult.Total -eq 0) { return $true }
            }
        } while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds)
    
        if ($ShouldExist) {
            Write-Warning "Trigger '$TriggerName' did not appear within timeout period ($TimeoutSeconds seconds)."
            return $null
        }
        else {
            Write-Warning "Trigger '$TriggerName' was still present after timeout period ($TimeoutSeconds seconds)."
            return $false
        }
    }
    
    function Remove-TestCUTrigger {
        param (
            [Parameter(Mandatory = $true)]
            [string]$TriggerName
        )
        
        $existingTrigger = (Invoke-CUQuery -Scheme 'Config' -Table 'TriggersConfiguration' `
                -Fields @("Name", "Id") -Where "Name='$triggerName'")
        if ($existingTrigger.Total -gt 0) {
            Remove-CUTrigger -TriggerId $existingTrigger.Data.Id
            Wait-ForTrigger -TriggerName $triggerName
        }
    }
}

Describe 'Test-Trigger Integration Tests' {
    # Array of every advanced trigger
    $triggers = @(
        @{
            Suffix           = "AdvancedFolder"
            RecordType       = "Folder"
            FilterDescriptor = @{
                Column             = 'Sessions'
                Value              = '1'
                ComparisonOperator = 'GreaterThanOrEqual'
            }
        },
        @{
            Suffix           = "AdvancedMachine"
            RecordType       = "Machine"
            FilterDescriptor = @{
                Column             = 'AvdDomainJoinedHealthCheckMessage'
                Value              = '*MONITOR*'
                ComparisonOperator = 'Equal'
            }
        },
        @{
            Suffix           = "AdvancedLogicalDisk"
            RecordType       = "LogicalDisk"
            FilterDescriptor = @{
                Column             = 'DiskName'
                Value              = 'C:\'
                ComparisonOperator = 'Equal'
            }
        },
        @{
            Suffix           = "AdvancedProcess"
            RecordType       = "Process"
            FilterDescriptor = @{
                Column             = 'sAccount'
                Value              = 'Oliver'
                ComparisonOperator = 'Equal'
            }
        },
        @{
            Suffix           = "AdvancedService"
            RecordType       = "Service"
            FilterDescriptor = @{
                Column             = 'ServiceDisplayName'
                Value              = 'Print Spooler'
                ComparisonOperator = 'Equal'
            }
        },
        @{
            Suffix           = "AdvancedAccount"
            RecordType       = "Account"
            FilterDescriptor = @{
                Column             = 'Account'
                Value              = 'Oliver'
                ComparisonOperator = 'Equal'
            }
        },
        @{
            Suffix           = "AdvancedApplication"
            RecordType       = "Application"
            FilterDescriptor = @{
                Column             = 'Description'
                Value              = 'MyApplication'
                ComparisonOperator = 'Equal'
            }
        },
        @{
            Suffix           = "AdvancedHost"
            RecordType       = "Host"
            FilterDescriptor = @{
                Column             = 'ActiveMemory'
                Value              = '0'
                ComparisonOperator = 'GreaterThanOrEqual'
            }
        },
        @{
            Suffix           = "AdvancedDatastore"
            RecordType       = "Datastore"
            FilterDescriptor = @{
                Column             = 'FreeSpacePercentage'
                Value              = '15'
                ComparisonOperator = 'LessThanOrEqual'
            }
        },
        @{
            Suffix           = "AdvancedDatastoresOnHost"
            RecordType       = "DatastoreOnHost"
            FilterDescriptor = @{
                Column             = 'DatastoreName'
                Value              = 'Big'
                ComparisonOperator = 'Equal'
            }
        },
        @{
            Suffix           = "AdvancedVirtualDisks"
            RecordType       = "VirtualDisk"
            FilterDescriptor = @{
                Column             = 'AttachedTo'
                Value              = 'Computer01'
                ComparisonOperator = 'Equal'
            }
        },
        @{
            Suffix           = "AdvancedFSLogixDisk"
            RecordType       = "FsLogixDisk"
            FilterDescriptor = @{
                Column             = 'DiskName'
                Value              = 'S:\'
                ComparisonOperator = 'Equal'
            }
        },
        @{
            Suffix           = "AdvancedNetScaler"
            RecordType       = "NetScaler"
            FilterDescriptor = @{
                Column             = 'HASync'
                Value              = 'Up'
                ComparisonOperator = 'Equal'
            }
        },
        @{
            Suffix           = "AdvancedLoadBalancer"
            RecordType       = "LoadBalancer"
            FilterDescriptor = @{
                Column             = 'LoadBalancerConnections'
                Value              = '10'
                ComparisonOperator = 'LessThanOrEqual'
            }
        },
        @{
            Suffix           = "AdvancedLBServiceGroup"
            RecordType       = "LBServiceGroup"
            FilterDescriptor = @{
                Column             = 'EffectiveState'
                Value              = 'Down'
                ComparisonOperator = 'Equal'
            }
        },
        @{
            Suffix           = "AdvancedLBService"
            RecordType       = "LBService"
            FilterDescriptor = @{
                Column             = 'ServiceLBName'
                Value              = 'LB1'
                ComparisonOperator = 'Equal'
            }
        },
        @{
            Suffix           = "AdvancedGateway"
            RecordType       = "Gateway"
            FilterDescriptor = @{
                Column             = 'GatewayCurrentUsers'
                Value              = '2'
                ComparisonOperator = 'Equal'
            }
        },
        @{
            Suffix           = "AdvancedNIC"
            RecordType       = "NIC"
            FilterDescriptor = @{
                Column             = 'NICBytesIn'
                Value              = '10'
                ComparisonOperator = 'GreaterThanOrEqual'
            }
        },
        @{
            Suffix           = "AdvancedSTA"
            RecordType       = "STA"
            FilterDescriptor = @{
                Column             = 'STAName'
                Value              = 'STA_1'
                ComparisonOperator = 'Equal'
            }
        },
        @{
            Suffix           = "AdvancedCitrixLicensing"
            RecordType       = "CitrixLicensing"
            FilterDescriptor = @{
                Column             = 'ctxCount'
                Value              = '0'
                ComparisonOperator = 'GreaterThanOrEqual'
            }
        },
        @{
            Suffix           = "AdvancedAvdHostPool"
            RecordType       = "AvdHostPool"
            FilterDescriptor = @{
                Column             = 'AzureCurrency'
                Value              = 'USD'
                ComparisonOperator = 'Equal'
            }
        },
        @{
            Suffix           = "AdvancedAvdWorkspace"
            RecordType       = "AvdWorkspace"
            FilterDescriptor = @{
                Column             = 'AvdAvailableMachinePercentage'
                Value              = '5'
                ComparisonOperator = 'GreaterThanOrEqual'
            }
        },
        @{
            Suffix           = "AdvancedAvdApplicationGroup"
            RecordType       = "AvdApplicationGroup"
            FilterDescriptor = @{
                Column             = 'AvdApplicationGroupId'
                Value              = 'A241'
                ComparisonOperator = 'Equal'
            }
        }
    )

    It 'Should <Suffix> return results or display warnings' -ForEach $triggers {
        $trigger = $PSItem
        $triggerName = Add-TestCUTrigger -TriggerDefinition $trigger
        
        $existingTriggerData = Wait-ForTrigger -TriggerName $triggerName -ShouldExist
        if (-not $existingTriggerData) {
            Throw "Trigger '$triggerName' did not appear within the expected timeout."
        }
        
        $warnings = $null
        $result = Test-Trigger -Name $triggerName -Records 1 -WarningVariable warnings
        
        if ($warnings) {
            $warnings | ForEach-Object { $_ | Should -Match '^Null Property|No data was returned' }
        }
        else {
            $result | Should -Not -BeNullOrEmpty
            $result.GetType().Fullname | Should -Be 'TriggerFilterResult[]'
            $result[0].ScheduleResult | Should -BeOfType 'System.Boolean'
            $result[0].ArePropertiesObserved | Should -BeOfType 'System.Boolean'
            $result[0].EvaluationResult | Should -BeOfType 'System.Boolean'
            $result[0].IdentityField | Should -Not -BeNullOrEmpty
            $result.DisplayResult()
        }
        
        Remove-TestCUTrigger -TriggerName $triggerName
    }
}