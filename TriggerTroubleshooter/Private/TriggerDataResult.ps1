class TriggerDataResult {
    [object] $RecordValue
    [string] $ComparisonUsed
    [bool] $ComparisonResult
    [string] $Key

    TriggerDataResult ([object] $recordValue, [string] $comparisonUsed, [bool] $comparisonResult, [string] $key) {
        $this.RecordValue = $recordValue
        $this.ComparisonUsed = $comparisonUsed
        $this.ComparisonResult = $comparisonResult
        $this.Key = $Key
    }
}