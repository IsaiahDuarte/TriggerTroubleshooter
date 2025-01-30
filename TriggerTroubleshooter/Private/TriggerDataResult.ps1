class TriggerDataResult {
    [object] $RecordValue
    [string] $ComparisonUsed
    [bool] $ComparisonResult
    [string] $key

    TriggerDataResult ([object] $recordValue, [string] $comparisonUsed, [bool] $comparisonResult, [string] $key) {
        $this.RecordValue = $recordValue
        $this.ComparisonUsed = $comparisonUsed
        $this.ComparisonResult = $comparisonResult
        $this.Key = $key
    }
}