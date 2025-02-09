<#
    .SYNOPSIS
        Represents detailed data for a trigger evaluation record. 

    .DESCRIPTION
        The TriggerDataResult class encapsulates the results of a single data record evaluation.
        It includes the record value, the comparison used during evaluation, comparison outcome, 
        and a key identifier for the record.

    .PARAMETER recordValue
        The value of the record being evaluated. This can be of any object type. 

    .PARAMETER comparisonUsed
        A string representing the comparison operator or method that was used during evaluation. 

    .PARAMETER comparisonResult
        A Boolean representing whether the record met the comparison criteria. 

    .PARAMETER key
        A string identifier to distinguish this record in the context of trigger data results. 
#>
using namespace System.Runtime.Serialization

[DataContract()]

class TriggerDataResult {
    [DataMember()]
    [object] $RecordValue

    [DataMember()]
    [string] $ComparisonUsed

    [DataMember()]
    [bool] $ComparisonResult
    
    [DataMember()]
    [string] $Key 
    TriggerDataResult ([object] $recordValue, [string] $comparisonUsed, [bool] $comparisonResult, [string] $key) {
        $this.RecordValue = $recordValue
        $this.ComparisonUsed = $comparisonUsed
        $this.ComparisonResult = $comparisonResult
        $this.Key = $key
    }
} 