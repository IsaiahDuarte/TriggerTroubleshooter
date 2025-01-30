class TriggerDataResult {
    [object] $RecordValue
    [string] $ComparisonUsed
    [bool] $ComparisonResult

    TriggerDataResult ([object] $recordValue, [string] $comparisonUsed, [bool] $comparisonResult) {
        $this.RecordValue = $recordValue
        $this.ComparisonUsed = $comparisonUsed
        $this.ComparisonResult = $comparisonResult
    }
}